require "spec_helper"

module Telephony
  describe ConversationsController do
    before do
      @routes = Engine.routes
    end

    describe '#hold' do
      context 'when hold works' do
        before do
          @conversation = mock(id: 1)
          @customer     = mock

          Conversation.stub(:find).and_return(@conversation)
          @conversation.stub(:hold!).and_return true
        end

        it "tells twilio to redirect the customer's call leg to the hold queue" do
          @conversation.should_receive(:hold!)
          xhr :post, :hold, id: @conversation.id
        end

        it "renders an empty json" do
          xhr :post, :hold, id: @conversation.id

          body = JSON.parse response.body
          body.should be_empty
        end
      end

      context 'when hold fails' do
        before do
          @conversation = Conversation.new
          @customer     = mock

          Conversation.stub(:find).and_return(@conversation)
        end

        context 'because of a twilio issue' do
          before do
            @conversation.stub(:hold!).and_raise(Telephony::Error::Connection.new("Some error"))
          end

          it "renders json errors" do
            xhr :post, :hold, id: 1

            body = JSON.parse response.body
            body['errors'].first.should == 'Hold failed. Please try again in a few seconds.'
            body['errors'].last.should == 'Some error'
          end
        end

        context 'because the customer has hung up' do
          before do
            @conversation.stub(:hold!).and_raise(Telephony::Error::NotInProgress.new("Some error"))
          end

          it "renders json errors" do
            xhr :post, :hold, id: 1

            body = JSON.parse response.body
            body['errors'].first.should == 'Hold failed. Please try again in a few seconds.'
            body['errors'].last.should == 'Some error'
          end
        end

        context 'because the call is in the wrong state' do
          it "renders json errors" do
            xhr :post, :hold, id: 1

            body = JSON.parse response.body
            body['errors'].first.should == 'Hold failed. Please try again in a few seconds.'
            body['errors'].last.should =~ /cannot transition/
          end
        end
      end
    end

    describe "#resume" do
      context "when resume works" do
        before do
          @conversation = Conversation.new

          Conversation.stub(:find).and_return(@conversation)
          @conversation.stub(:resume!).and_return true
        end

        it "tells twilio to redirect the customer's call leg to the conference's room" do
          @conversation.should_receive :resume!
          xhr :post, :resume, id: 1

          body = JSON.parse response.body
          body.should be_empty
        end
      end

      context 'when resume fails' do
        before do
          @conversation = Conversation.new

          Conversation.stub(:find).and_return(@conversation)
        end

        context 'because of a twilio issue' do
          before do
            @conversation.stub(:resume!).and_raise(Telephony::Error::Connection.new("Some error"))
          end

          it "renders json errors" do
            xhr :post, :resume, id: 1

            body = JSON.parse response.body
            body['errors'].first.should == 'Resume failed. Please try again in a few seconds.'
            body['errors'].last.should == 'Some error'
          end
        end

        context 'because the customer has hung up' do
          before do
            @conversation.stub(:resume!).and_raise(Telephony::Error::NotInProgress.new("Some error"))
          end

          it "renders json errors" do
            xhr :post, :resume, id: 1

            body = JSON.parse response.body
            body['errors'].first.should == 'Resume failed. Please try again in a few seconds.'
            body['errors'].last.should == 'Some error'
          end
        end

        context 'because the call is in the wrong state' do
          it "renders json errors" do
            xhr :post, :resume, id: 1

            body = JSON.parse response.body
            body['errors'].first.should == 'Resume failed. Please try again in a few seconds.'
            body['errors'].last.should =~ /cannot transition/
          end
        end
      end
    end

    describe "#search" do
      before do
        @conversation = create :conversation
        xhr :get, :search
      end

      it "returns conversations as json" do
        body = JSON.parse response.body
        body['conversations'][0]['id'].should == @conversation.id
        body['total_count'].should == 1
      end
    end

    describe "#create", :vcr do
      context "by default" do
        before do
          agent = create :agent
          attributes = {
            from:      '310-456-7890',
            to:        '310-765-4321',
            loan_id:   1,
            from_id:   agent.csr_id,
            from_type: 'csr'
          }
          @existing_whitelist = Telephony.whitelist
          Telephony.whitelist = [attributes[:from], attributes[:to]]
          @conversation_count = Conversation.count
          # Twilio doesn't allow you to buy new numbers using a test account
          Telephony.provider.stub(:caller_id_for).and_return attributes[:from]

          xhr :post, :create, attributes
        end

        after do
          Telephony.whitelist = @existing_whitelist
        end

        it "creates a new conversation" do
          Conversation.count.should == @conversation_count + 1
        end

        it 'creates a new call' do
          Call.count.should == 2
        end

        it 'returns the conversation as JSON' do
          conversation = Conversation.last
          json = JSON response.body
          json['id'].should == conversation.id
        end
      end

      context "when an exception occurs" do
        before do
          agent = create :agent
          attributes = {
            from:      '310-456-7890',
            to:        '310-765-4321',
            loan_id:   1,
            from_id:   agent.csr_id,
            from_type: 'csr'
          }

          Conversation
            .stub(:begin!)
            .and_raise(Telephony::Error::Connection.new("Call failed"))

          xhr :post, :create, attributes
        end

        it 'return a 500 failure response' do
          response.code.should == "500"
        end

        it 'returns an error message as JSON' do
          json = JSON response.body
          json.should include('errors')
          errors = json['errors']
          errors.should have(2).error
          errors[1].should == 'Call failed'
        end
      end
    end
  end
end
