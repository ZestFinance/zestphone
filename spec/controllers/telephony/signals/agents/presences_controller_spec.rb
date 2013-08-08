require 'spec_helper'

module Telephony
  module Signals
    module Agents
      describe PresencesController do
        before do
          @routes = Engine.routes
        end

        describe '#authenticate' do
          context 'by default' do
            before do
              csr_id = 'csr_id'
              csr_type = 'A'
              csr_name = 'csr_name'
              csr_phone_number = "555-555-1234"
              csr_phone_ext = 'csr_phone_ext'

              agent = create :agent, csr_id: csr_id

              VCR.use_cassette "Pusher channel as JSON", match_requests_on: [:path] do
                post :authenticate,
                  socket_id: "1234.5678",
                  channel_name: "presence-#{csr_id}",
                  csr_id: csr_id,
                  csr_type: csr_type,
                  csr_name: csr_name,
                  csr_phone_number: csr_phone_number,
                  csr_phone_ext: csr_phone_ext
              end
            end

            it 'returns the Pusher channel data as JSON' do
              json = JSON response.body
              channel_data = JSON json['channel_data']
              channel_data['user_id'].should == Agent.last.id
            end

            it 'pushes a queue change event' do
              @agent = create :available_agent
              csr_id = @agent.csr_id
              Conversation.stub(:queue_size).and_return 1

              VCR.use_cassette "Authenticating an online user", match_requests_on: [:path] do
                post :authenticate,
                  socket_id: "1234.5678",
                  channel_name: "presence-#{csr_id}",
                  csr_id: csr_id

                request = VCR.current_cassette.serializable_hash['http_interactions'][2]['request']
                body = JSON request['body']['string']
                body['name'].should == 'QueueChange'
                body['channels'].first.should == "csrs-1"
                data = JSON body['data']
                data['size'].should == 1
              end
            end
          end

          context "given an agent that's online" do
            before do
              @agent = create :available_agent
            end

            it "publishes the agent's current status" do
              csr_id = @agent.csr_id
              csr_type = 'A'
              csr_name = 'csr_name'
              csr_phone_number = "555-555-1234"
              csr_phone_ext = 'csr_phone_ext'

              VCR.use_cassette "Authenticating an online user", match_requests_on: [:path] do
                post :authenticate,
                  socket_id: "1234.5678",
                  channel_name: "presence-#{csr_id}",
                  csr_id: csr_id,
                  csr_type: csr_type,
                  csr_name: csr_name,
                  csr_phone_number: csr_phone_number,
                  csr_phone_ext: csr_phone_ext

                request = VCR.current_cassette.serializable_hash['http_interactions'][1]['request']
                body = JSON request['body']['string']
                request_data = JSON body['data']
                request_data['status'].should == @agent.status
              end
            end
          end

          context "given an agent that's offline" do
            context "by default" do
              before do
                @agent = create :offline_agent
                PusherEventPublisher.stub :publish

                post :authenticate,
                  socket_id: "1234.5678",
                  channel_name: "presence-#{@agent.csr_id}",
                  csr_id: @agent.csr_id
              end

              it "sets the agent to available" do
                @agent.reload.should be_available
              end
            end

            context "given a default agent status" do
              before do
                @agent = create :offline_agent
                PusherEventPublisher.stub :publish

                post :authenticate,
                  socket_id: "1234.5678",
                  channel_name: "presence-#{@agent.csr_id}",
                  csr_id: @agent.csr_id,
                  csr_default_status: "not_available"
              end

              it "sets the agent to not available" do
                @agent.reload.should be_not_available
              end
            end
          end
        end

        describe '#create' do
          before do
            @agent = create :offline_agent
            @payload = {
              "presence" => {
                "time_ms" => 9223372036854775705,
                "events" => [
                  { "name" => "member_added",
                    "channel" => "presence-#{@agent.csr_id}",
                    "user_id" => "#{@agent.id}" }
                ]
              }
            }
            sign_pusher_request(@payload)
          end

          it "returns success" do
            VCR.use_cassette example.description, match_requests_on: [:path] do
              post :create, @payload
            end

            response.should be_success
          end
        end
      end
    end
  end
end
