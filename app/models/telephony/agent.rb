module Telephony
  class Agent < Base
    include AgentStateMachine

    OFFLINE = "offline"
    AVAILABLE = "available"
    NOT_AVAILABLE = "not_available"
    ON_A_CALL = "on_a_call"

    STATUS_SORT_ORDER = {
      AVAILABLE => 0,
      ON_A_CALL => 1,
      NOT_AVAILABLE => 2,
      OFFLINE => 3
    }

    module PhoneType
      PHONE         = "phone"
      TWILIO_CLIENT = "twilio_client"
      SIP           = "sip"

      ALL = [PHONE, TWILIO_CLIENT, SIP]
    end

    PhoneType::ALL.each do |type|
      define_method "uses_#{type}?".to_sym do
        phone_type == type
      end
    end

    has_many :calls

    attr_accessible :csr_id,
      :status,
      :generate_caller_id,
      :name,
      :phone_ext,
      :phone_number,
      :phone_type,
      :csr_type,
      :sip_number,
      :call_center_name,
      :transferable_agents

    serialize :transferable_agents, Array

    validates :csr_id,       presence:  true
    validates :phone_type,   inclusion: { :in => PhoneType::ALL }
    validates :sip_number,   presence: true, :if => :uses_sip?
    validates :phone_number, presence: true, :if => :uses_phone?

    def self.sort_by_status agents
      agents.sort_by { |agent| STATUS_SORT_ORDER[agent.status] }
    end

    def self.all_transferable_for_csr_id csr_id
      agent = find_by_csr_id csr_id

      transferables = select([:id, :csr_id, :csr_type, :status, :name, :phone_ext, :phone_number])

      if agent && agent.transferable_agents.count > 0
        transferables = transferables.where(csr_id: agent.transferable_agents)
      end

      sort_by_status(transferables)
    end

    def self.update_or_create_by_widget_data data
      agent = find_or_create_by_csr_id data[:csr_id]
      agent.update_attributes({
        csr_type: data[:csr_type],
        name: data[:csr_name],
        generate_caller_id: data[:csr_generate_caller_id],
        phone_number: data[:csr_phone_number],
        phone_ext: data[:csr_phone_ext],
        sip_number: data[:csr_sip_number],
        call_center_name: data[:csr_call_center_name],
        phone_type: data[:csr_phone_type].present? ? data[:csr_phone_type] : PhoneType::PHONE,
        transferable_agents: data[:csr_transferable_agents].present? ? JSON.parse(data[:csr_transferable_agents]) : []
      })
      agent
    end

    def self.find_with_lock agent_id
      transaction do
        yield find agent_id, lock: true
      end
    end

    def transferrable?
      available?
    end

    def process_presence_event event, timestamp
      if event == 'member_added'
        update_status_by_event :came_online, timestamp
      else
        job = Telephony::Jobs::AgentOffline.new id, timestamp
        if Telephony::DELAYED_JOB.respond_to?(:enqueue)
          Telephony::DELAYED_JOB.enqueue job, run_at: 30.seconds.from_now
        else
          job.update_status
        end
      end
    end

    def update_status_by_event presence_event, timestamp
      return if timestamp_of_last_presence_event > timestamp

      self.send presence_event.to_sym
      self.update_attribute :timestamp_of_last_presence_event, timestamp
    end

    def active_call
      calls.where("state <> 'terminated'").last
    end

    def active_conversation_id
      return nil unless on_a_call?
      call = active_call
      call.conversation_id if call
    end

    def verify_status!
      return unless on_a_call?
      call = active_call

      if call.nil?
        with_lock { not_available! if (active_call.nil? and on_a_call?) }
      elsif call.created_at < 5.minutes.ago && Telephony.provider.call_ended?(call.sid)
        Conversation.find_with_lock(call.conversation_id) do
          call.reload.terminate
        end
      end
    end

    def publish_status_change
      PusherEventPublisher.publish channel: "csrs-#{csr_id}",
        name: 'statusChange',
        data: {
          status: status,
          timestamp: Integer(Time.now.to_f * 1000)
        }
    end

    def number with_protocol = false
      case phone_type
      when PhoneType::SIP
        sip_string with_protocol
      when PhoneType::TWILIO_CLIENT
        client_string with_protocol
      else
        phone_number
      end
    end

    def encode_with coder
      coder['attributes'] = {
        'id'     => attributes['id'],
        'csr_id' => attributes['csr_id']
      }
    end

    private

    def client_string with_protocol = false
      "#{'client:' if with_protocol}agent#{csr_id}"
    end

    def sip_string with_protocol = false
      "#{'sip:' if with_protocol}#{sip_address}"
    end

    def sip_address
      "#{sip_number}@#{call_center.host}"
    end

    def call_center
      CallCenter.find_by_name call_center_name
    end
  end
end
