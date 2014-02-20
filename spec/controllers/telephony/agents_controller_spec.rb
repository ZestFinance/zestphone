require 'spec_helper'

module Telephony
  describe AgentsController do
    before do
      @routes = Engine.routes
    end

    describe "#terminate_active_call" do
      context "given an invalid csr id" do
        before do
         post :terminate_active_call, id: :bogus_id
        end
        it "responds with a status 400" do
          response.should be_bad_request
        end
      end
      context "given a valid csr id" do
        before do
         create :available_agent, :csr_id => 123
         Agent.any_instance.should_receive(:terminate_active_call_and_conversation)
         post :terminate_active_call, id: 123
        end
        it "responds successfully" do
           response.should be_success
        end
      end
    end

    describe "#update" do
      context "given an invalid agent params" do
        before do
          agent = create :invalid_agent

          put :update,
            csr_phone_type: 'invalid',
            csr_type: "B",
            csr_id: agent.csr_id,
            id: agent.csr_id
        end

        it "responds with a status 400" do
          response.should be_bad_request
        end

        it "renders errors" do
          body = JSON.parse response.body
          body['errors'].should == ["Phone type is not included in the list"]
        end
      end
    end

    describe '#status' do
      before do
        @agent = create :available_agent, :csr_id => 123
        put :status, :event => 'not_available', :id => @agent.csr_id
        @agent.reload
      end

      it 'transitions status based on the given event' do
        @agent.status.should == Telephony::Agent::NOT_AVAILABLE
      end

      it 'returns the updated agent as JSON' do
        json = JSON response.body
        json.should include('status' => @agent.status)
        json.should include('csr_id' => @agent.csr_id)
      end
    end

    describe '#show_by_csr_id' do
      before do
        @agent = create :available_agent, :csr_id => 123
        Agent.any_instance.stub(:active_conversation_id).and_return(321)
        get :show_by_csr_id, :csr_id => @agent.csr_id
      end

      it 'returns the agent' do
        json = JSON response.body
        json.should include('active_conversation_id' => 321)
      end
    end

    describe "#index" do
      context "by default" do
        it "returns a list of agents" do
          create :available_agent, csr_id: 123
          create :offline_agent, csr_id: 11
          create :available_agent, csr_id: 12
          get :index

          res = JSON(response.body)
          res.size.should == 3
          res[0].should include('csr_id' => 123)
          res[1].should include('csr_id' => 12)
          res[2].should include('csr_id' => 11)
        end
      end

      context "given a csr id" do
        it "returns a list of transferable agents for that agent" do
          agent = create :available_agent,
            csr_id: 123,
            transferable_agents: [11, 12]
          create :offline_agent, csr_id: 11
          create :available_agent, csr_id: 12
          get :index, csr_id: agent.csr_id

          res = JSON(response.body)
          res.size.should == 2
          res[0].should include('csr_id' => 12)
          res[1].should include('csr_id' => 11)
        end
      end
    end
  end
end
