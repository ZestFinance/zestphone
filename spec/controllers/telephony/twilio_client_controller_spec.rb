require 'spec_helper'

module Telephony
  describe TwilioClientController do
    render_views

    before do
      @routes = Engine.routes
    end

    describe '#index' do
      before do
        get :index
      end

      it 'renders the twilio client page' do
        response.should be_ok
        response.content_type.should == "text/html"
      end
    end

    describe '#token' do
      context 'by default' do
        before do
          controller.should_receive(:generate_token_for)
            .with("agent123")
            .and_return("a_new_token")
          get :token, { csr_id: 123 }
        end

        it 'returns the Twilio Client capability token' do
          response.should be_ok
          response.content_type.should == "application/json"
          data = JSON.parse(response.body)
          data['token'].should == "a_new_token"
        end
      end

      context 'given an invalid csr id' do
        before do
          get :token
        end

        it 'returns a 400 response' do
          response.code.should == "400"
        end

        it 'returns an error message as JSON' do
          json = JSON response.body
          json.should include('errors')
          errors = json['errors']
          errors.should have(1).error
          errors[0].should == 'Invalid csr id'
        end
      end
    end
  end
end
