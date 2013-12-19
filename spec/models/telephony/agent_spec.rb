require 'spec_helper'

module Telephony
  describe Agent do
    before { VCR.insert_cassette "Pusher channel as JSON", match_requests_on: [:path] }
    after  { VCR.eject_cassette }

    describe "#valid?" do
      it "requires a csr id" do
        agent = Agent.create csr_id: nil
        agent.should_not be_valid
      end

      it "requires a valid phone_type" do
        agent = build :agent, phone_type: 'invalid'
        agent.should_not be_valid
        agent.should have(1).error_on(:phone_type)
      end

      it "requires a sip number if agent uses sip" do
        agent = build :agent, phone_type: 'sip', sip_number: nil
        agent.should_not be_valid
        agent.should have(1).error_on(:sip_number)
      end

      it "requires a phone number if agent uses phone" do
        agent = build :agent, phone_type: 'phone', phone_number: nil
        agent.should_not be_valid
        agent.should have(1).error_on(:phone_number)
      end
    end

    describe '.new' do
      it 'defaults its status to "offline"' do
        agent = create :agent
        agent.status.should == 'offline'
      end

      it 'defaults its phone_type to "phone"' do
        agent = build :agent
        agent.phone_type.should == Agent::PhoneType::PHONE
      end
    end

    describe ".sort_by_status" do
      it "orders by agents by status" do
        agent1 = create :available_agent
        agent2 = create :offline_agent
        agent3 = create :not_available_agent
        agent4 = create :on_a_call_agent
        agents = Agent.sort_by_status [agent1, agent2, agent3, agent4]

        agents.map(&:id).should == [agent1.id, agent4.id, agent3.id, agent2.id]
      end
    end

    describe ".all_transferable_for_csr_id" do
      context "given transferable agents" do
        before do
          @agent = create :agent,
            csr_id: 123,
            transferable_agents: [11, 12]
        end

        it "returns transferable agents sorted by status" do
          agent1 = create :available_agent, csr_id: 12
          agent2 = create :offline_agent, csr_id: 11
          create :not_available_agent, csr_id: 13
          create :on_a_call_agent, csr_id: 14
          agents = Agent.all_transferable_for_csr_id 123

          agents.map(&:id).should == [agent1.id, agent2.id]
        end
      end

      context "given no transferable agents" do
        before do
          @agent = create :agent,
            csr_id: 123,
            transferable_agents: []
        end

        it "returns all agents sorted by status" do
          agent1 = create :available_agent, csr_id: 12
          agent2 = create :offline_agent, csr_id: 11
          agent3 = create :not_available_agent, csr_id: 13
          agent4 = create :on_a_call_agent, csr_id: 14
          agents = Agent.all_transferable_for_csr_id 123

          agents.map(&:id).should == [agent1.id, agent4.id, agent3.id, agent2.id, @agent.id]
        end
      end

      context "given no valid csr id" do
        before do
          @agent = create :agent,
            csr_id: 123,
            transferable_agents: []
        end

        it "returns all agents sorted by status" do
          agent1 = create :available_agent, csr_id: 12
          agent2 = create :offline_agent, csr_id: 11
          agent3 = create :not_available_agent, csr_id: 13
          agent4 = create :on_a_call_agent, csr_id: 14
          agents = Agent.all_transferable_for_csr_id ''

          agents.map(&:id).should == [agent1.id, agent4.id, agent3.id, agent2.id, @agent.id]
        end
      end
    end

    describe '.update_or_create_by_widget_data' do
      context "given an existing agent" do
        before do
          @existing_agent = create :on_a_call_agent, name: nil, phone_ext: nil
        end

        it 'finds the agent' do
          data = { csr_id: @existing_agent.csr_id }
          agent = Agent.update_or_create_by_widget_data data

          agent.should == @existing_agent
        end

        it "updates agent's attributes" do
          data = {
            csr_id: @existing_agent.csr_id,
            csr_type: "A",
            csr_generate_caller_id: "true",
            csr_name: "csr_name",
            csr_phone_number: "555-555-1234",
            csr_phone_ext: "csr_phone_ext",
            csr_sip_number: "432",
            csr_call_center_name: "other_location",
            csr_phone_type: Agent::PhoneType::SIP,
            csr_transferable_agents: [1, 2].to_json
          }
          Agent.update_or_create_by_widget_data data
          @existing_agent.reload

          @existing_agent.csr_type.should == "A"
          @existing_agent.generate_caller_id.should be_true
          @existing_agent.name.should == "csr_name"
          @existing_agent.phone_number.should == "555-555-1234"
          @existing_agent.phone_ext.should == "csr_phone_ext"
          @existing_agent.sip_number.should == "432"
          @existing_agent.call_center_name.should == "other_location"
          @existing_agent.phone_type.should == Agent::PhoneType::SIP
          @existing_agent.transferable_agents.should == [1, 2]
        end
      end

      context "given a new agent" do
        it 'creates the agent' do
          data = {
            csr_id: 123,
            csr_type: "A",
            csr_name: 'csr_name',
            csr_phone_number: "555-555-1234",
            csr_phone_ext: 'csr_phone_ext'
          }
          agent = Agent.update_or_create_by_widget_data data

          agent.csr_id.should == 123
          agent.csr_type.should == "A"
          agent.name.should == 'csr_name'
          agent.phone_ext.should == 'csr_phone_ext'
          agent.phone_number.should == '555-555-1234'
        end
      end
    end

    describe '#transferrable?' do
      context 'given an available agent' do
        before do
          @agent = create :available_agent
        end

        it 'returns true' do
          @agent.should be_transferrable
        end
      end

      context 'given an unavailable agent' do
        before do
          @agent = create :not_available_agent
        end

        it 'returns true' do
          @agent.should_not be_transferrable
        end
      end
    end

    describe '#process_presence_event' do
      context "given a member_added event"  do
        before do
          @agent = create type_of_agent
          @timestamp = 1234
          @agent.process_presence_event 'member_added', @timestamp
        end

        context "when the agent is offline" do
          let(:type_of_agent) { :offline_agent }

          it "updates the agent's status to be available" do
            @agent.reload.should be_available
          end
        end

        context "when the agent is on_a_call" do
          let(:type_of_agent) { :on_a_call_agent }

          it "doesn't update the status" do
            @agent.reload.should be_on_a_call
          end
        end

        context "whatever the agent's status is" do
          let(:type_of_agent) { :on_a_call_agent }

          it "unconditionally updates the timestamp" do
            @agent.reload.timestamp_of_last_presence_event.should == @timestamp
          end
        end
      end

      context "given a member_removed event"  do
        let(:job) { mock(Telephony::Jobs::AgentOffline)}
        let(:timestamp) { 1234 }

        before do
          @agent = create :available_agent
        end

        context "delayed job is defined" do
          before do
            Telephony::DELAYED_JOB.should_receive(:enqueue)
            Telephony::Jobs::AgentOffline.stub(:new)
              .with(@agent.id, timestamp).and_return { job }
          end

          it "defer the handling of an offline webhook" do
            @agent.process_presence_event "member_removed", timestamp
          end
        end

        context "delayed job is not defined" do
          before do
            Telephony::Jobs::AgentOffline.stub(:new)
              .with(@agent.id, timestamp).and_return(job)
          end

          it "calls the job update_status directly" do
            job.should_receive(:update_status)
            @agent.process_presence_event "member_removed", timestamp
          end
        end
      end
    end

    describe '#terminate_active_call' do
      subject { Agent.new.terminate_active_call }

      context "given an agent that's on a call" do
        let(:active_call) { double terminate!: :terminated }
        before { Agent.any_instance.should_receive(:active_call)
                                   .twice
                                   .and_return active_call }
        it { should == :terminated }
      end

      context "given an agent that's not on a call" do
        let(:active_call) { nil }
        before { Agent.any_instance.should_receive(:active_call) }
        it { should == nil }
      end

    end

    describe '#verify_status!' do
      context "given an agent that's on a call" do
        before do
          @agent = create :on_a_call_agent
        end

        context 'and the call has ended locally' do
          before do
            create :terminated_call,
              agent: @agent

            @agent.verify_status!
          end

          it 'sets itself to not available' do
            @agent.reload
            @agent.should be_not_available
          end
        end

        context 'and the call has ended remotely but not locally' do
          before do
            @call = create :in_progress_call,
              agent: @agent,
              created_at: call_created_at

            provider = double 'provider'
            provider
              .stub(:call_ended?)
              .with(@call.sid)
              .and_return(true)

            Telephony
              .stub(:provider)
              .and_return(provider)

            @agent.verify_status!
          end

          context 'and the call is over 5 minutes old' do
            let(:call_created_at) { 6.minutes.ago }

            it 'terminates the call' do
              @call.reload
              @call.should be_terminated
            end
          end

          context 'and the call is less than 5 minutes old' do
            let(:call_created_at) { 4.minutes.ago }

            it 'does not the call' do
              @call.reload
              @call.should_not be_terminated
            end
          end
        end

        context 'and the call has not ended remotely' do
          before do
            provider = double 'provider'
            provider
              .stub(:call_ended?)
              .and_return(false)

            Telephony
              .stub(:provider)
              .and_return(provider)

            @call = create :in_progress_call,
              agent: @agent

            @agent.verify_status!
          end

          it 'does not try to terminate the call' do
            @call.reload
            @call.should_not be_terminated
          end
        end
      end

      context "given an agent that's not on a call" do
        before do
          provider = double 'provider'
          provider.should_not_receive(:call_ended?)

          Telephony
            .stub(:provider)
            .and_return(provider)

          @agent = create :offline_agent
        end

        it 'does not try to verify a call status' do
          @agent.verify_status!
        end
      end
    end
  end

  describe "#timestamp_of_last_presence_event" do
    it "defaults to zero" do
      agent = create :agent
      agent.timestamp_of_last_presence_event.should == 0
    end

    it "can store big integer" do
      agent = create :agent, :timestamp_of_last_presence_event => 9223372036854775807
      agent.reload
      agent.timestamp_of_last_presence_event.should == 9223372036854775807
    end
  end

  describe '#publish_status_change' do
    before do
      @agent = create :available_agent
    end

    it 'asks the event publisher to publish its new status' do
      Timecop.freeze do
        PusherEventPublisher
          .should_receive(:publish)
          .with(channel: "csrs-#{@agent.csr_id}",
                name: 'statusChange',
                data: {
                  status: @agent.status,
                  timestamp: Integer(Time.now.to_f * 1000)
                })

        @agent.publish_status_change
      end
    end
  end

  describe "#number" do
    before  do
      @agent = build :agent,
        sip_number: '123',
        call_center_name: 'other_location',
        phone_number: '3213214321'
    end
    subject { @agent.number @with_protocol }

    context "when phone_type is 'sip'" do
      before { @agent.phone_type = Agent::PhoneType::SIP }

      context "by default" do
        it { should == "123@192.168.1.2" }
      end

      context "called with true" do
        before { @with_protocol = true }
        it { should == "sip:123@192.168.1.2" }
      end
    end

    context "when phone_type is 'twilio_client'" do
      before { @agent.phone_type = Agent::PhoneType::TWILIO_CLIENT }

      context "by default" do
        it { should == "agent#{@agent.csr_id}" }
      end

      context "called with true" do
        before { @with_protocol = true }
        it { should == "client:agent#{@agent.csr_id}"}
      end
    end

    context "when phone_type is 'phone'" do
      before { @agent.phone_type = Agent::PhoneType::PHONE }
      it { should == @agent.phone_number }
    end
  end

  describe "#uses_phone_type?" do
    Agent::PhoneType::ALL.each do |type|
      it "defines question mark method for #{type} phone type" do
        agent = build :agent, phone_type: type
        agent.should(send "be_uses_#{type}".to_sym)
      end
    end
  end

  describe "#encode_with" do
    context "when serializing into a string with limited length" do
      it "overrides ActiveRecord::Base#encode_with with selected attributes" do
        agent = create :agent

        deserialized_agent = YAML.load agent.to_yaml
        deserialized_agent.attributes.keys.should == %w(id csr_id)
        deserialized_agent.id.should == agent.id
        deserialized_agent.csr_id.should == agent.csr_id
      end
    end
  end
end
