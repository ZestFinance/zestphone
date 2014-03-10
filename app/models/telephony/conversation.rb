module Telephony
  class Conversation < Base
    extend Telephony::NumberHelper
    include ConversationStateMachine

    module CONVERSATION_TYPES
      OUTBOUND = 'outbound'
      INBOUND = 'inbound'
    end

    has_many :calls, order: 'id'
    belongs_to :transferee, class_name: 'Agent'
    has_many :events, class_name: 'Events::Base'

    attr_accessible :state,
      :loan_id,
      :initiator_id,
      :caller_id,
      :number,
      :conversation_type,
      :transferee

    scope :old_and_active, -> { where("created_at < ? and state != 'terminated'", 48.hours.ago) }

    def self.clean_up!(options = {})
      logger = options[:logger] || Rails.logger

      if options[:log] == true
        old_and_active.each do |conversation|
          logger.info(conversation.inspect)
        end
      end

      if options[:dry_run] != true
        old_and_active.update_all(state: 'terminated')
      end
    end

    def self.begin!(args)
      agent = Agent.find_by_csr_id args[:from_id]

      if agent.generate_caller_id?
        caller_id = Telephony.provider.caller_id_for extract_area_code(args[:to])
      else
        caller_id = Telephony.provider.outbound_caller_id
      end

      conversation = transaction do
        conversation = create loan_id:      args[:loan_id],
                              initiator_id: args[:from_id],
                              caller_id:    caller_id

        conversation.calls.create! number:           agent.number,
                                   participant_id:   args[:from_id],
                                   participant_type: args[:from_type],
                                   agent:            agent

        conversation.calls.create! number: args[:to],
                                   participant_id:   args[:to_id],
                                   participant_type: args[:to_type]
        conversation
      end
      conversation.connect!
      conversation.initiating_call.connect!
      conversation.initiating_call.make!
      conversation
    end

    def self.find_with_lock(id)
      transaction do
        yield find(id, joins: {calls: :agent}, lock: true, readonly: false)
      end
    end

    def self.find_inbound_with_lock(id)
      transaction do
        yield find(id, lock: true)
      end
    end

    def self.find_inbound_calls_with_lock(id)
      transaction do
        yield find(id, joins: :calls, lock: true)
      end
    end

    def self.create_inbound!(args)
      create! args.merge(conversation_type: 'inbound')
    end

    def self.queue_size
      where(state: 'enqueued').count
    end

    def not_initiated_call
      calls.detect(&:not_initiated?)
    end

    def active_on_call
      calls.reject(&:terminated?)
    end

    def check_for_successful_transfer
      complete_two_step_transfer if all_agents_in_conference? &&
                                    (customer.in_conference? || customer.in_progress_hold?)
    end

    def check_for_successful_hold
      complete_hold if all_agents_in_conference? && customer.in_progress_hold?
    end

    def check_for_successful_resume
      complete_resume if all_agents_in_conference? && customer.in_conference?
    end

    def terminate_conferenced_calls(except_call_id)
      calls.select(&:in_conference?).each do |call|
        if call.id != except_call_id
          Telephony.provider.hangup call.sid
          call.terminate!
        end
      end
    end

    def check_for_terminate
      if active_on_call.size == 0
        terminate!
      elsif one_step_transferring? && active_on_call.size == 1
        fail_one_step_transfer!
      elsif leaving_voicemail? && active_on_call.size == 1
        # noop
      elsif inbound? && connecting? && active_on_call.first == customer
        rona!
      elsif active_on_call.size == 1
        lone_call = active_on_call.first
        if lone_call.in_conference? || lone_call.in_progress_hold?
          Telephony.provider.hangup lone_call.sid if lone_call.sid
        end
        lone_call.terminate!
      elsif (two_step_transferring? || two_step_transferring_hold?) && active_on_call.size == 2
        fail_two_step_transfer!
      elsif (in_progress_two_step_transfer? || in_progress_two_step_transfer_hold?) && active_on_call.size == 2 && customer.terminated?
        customer_left_two_step_transfer!
      elsif (in_progress_two_step_transfer? || in_progress_two_step_transfer_hold?) && active_on_call.size == 2
        leave_two_step_transfer!
      end
    end

    def child_call(sid=nil)
      (sid && calls.detect { |c| c.sid == sid }) || active_on_call[1]
    end

    def customer
      calls.detect { |call| !call.agent? }
    end

    def initiating_call
      calls.first
    end

    def hold!
      initiate_hold!

      if customer.in_conference?
        customer.redirect_to_hold
        if active_agent_legs.size == 1
          # If there's only one agent on, redirect them so they
          # get the conference music
          active_agent_leg.redirect_to_conference
        end
      elsif customer == child_call
        customer.redirect_to_hold
      else
        child_call.redirect_to_conference
      end
    end

    def resume!
      initiate_resume!
      customer.redirect_to_conference
   end

    def transfer!(csr_id, one_step)
      unless in_progress? || in_progress_hold?
        errors[:base] << "Conversation already #{state}"
        return false
      end

      agent = Agent.find_by_csr_id csr_id

      agent.with_lock do
        one_step ? one_step_transfer!(agent) : two_step_transfer!(agent)
      end
    end

    def as_json(options={})
      super({ include: { calls: { include: :recordings } } }.deep_merge(options))
    end

    def outbound?
      conversation_type == CONVERSATION_TYPES::OUTBOUND
    end

    def inbound?
      conversation_type == CONVERSATION_TYPES::INBOUND
    end

    def active_agent_legs
      active_on_call.select do |call|
        call.agent.present?
      end
    end

    def active_agent_leg
      active_agent_legs.first
    end

    def first_active_agent
      leg = active_agent_legs[0]
      leg.agent if leg
    end

    def first_inactive_agent
      leg = calls.detect do |call|
        call.agent? && call.terminated?
      end
      leg.agent if leg
    end

    def second_active_agent
      leg = active_agent_legs[1]
      leg.agent if leg
    end

    private

    def one_step_transfer!(agent)
      agent2_leg = calls.create number: agent.phone_number,
                                participant_id: agent.csr_id,
                                participant_type: 'csr',
                                agent: agent

      if agent.transferrable?
        initiate_one_step_transfer!
        agent2_leg.connect!
      else
        leave_voicemail!
        agent2_leg.straight_to_voicemail!
      end

      customer.dial_agent!
      customer.redirect_to_dial

    rescue => error
      Rails.logger.error "Failed to one-step transfer: #{error.message}"
      errors[:base] << "#{error.message}"
      agent2_leg.terminate
      false
    end

    def two_step_transfer!(agent)
      unless agent.transferrable?
        errors[:base] << 'Agent is unavailable'
        return false
      end

      agent2_leg = calls.create number: agent.phone_number,
                                participant_id: agent.csr_id,
                                participant_type: 'csr',
                                agent: agent

      initiate_two_step_transfer!

      child_call.redirect_to_conference unless two_step_transferring_hold?
      agent2_leg.dial_into_conference!
      agent2_leg.connect!

    rescue => error
      Rails.logger.error "Failed to two-step transfer: #{error.message}"
      errors[:base] << "#{error.message}"
      agent2_leg.terminate!
      false
    end

    def all_agents_in_conference?
      active_agent_legs.all?(&:in_conference?)
    end
  end
end
