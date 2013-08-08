require 'spec_helper'

module Telephony::Concerns::Controllers
  describe TwilioRequestVerifier, :type => :controller do
    let(:token) { '123456789' }
    let(:signature) { '3ugjK9yQlIvxbBwmdF/7BfDG5Uk=' }

    controller do
      include TwilioRequestVerifier

      def index
        head :ok
      end
    end

    it 'verifies twilio request' do
      twilio_params = {
        'ToState' => 'California',
        'CalledState' => 'California',
        'Direction' => 'inbound',
        'FromState' => 'CA',
        'AccountSid' => 'ACFAKEACCOUNTSID',
        'Caller' => '+15555551235',
        'CallerZip' => '94108',
        'CallerCountry' => 'US',
        'From' => '+15555551235',
        'FromCity' => 'SAN FRANCISCO',
        'CallerCity' => 'SAN FRANCISCO',
        'To' => '+15555551235',
        'FromZip' => '94108',
        'FromCountry' => 'US',
        'ToCity' => '',
        'CallStatus' => 'ringing',
        'CalledCity' => '',
        'CallerState' => 'CA',
        'CalledZip' => '',
        'ToZip' => '',
        'ToCountry' => 'US',
        'CallSid' => 'CAFAKECALLSID',
        'CalledCountry' => 'US',
        'Called' => '+15555551234',
        'ApiVersion' => '2010-04-01',
        'ApplicationSid' => 'APFAKEAPPLICATIONSID'
      }

      controller.stub(:twilio_config).and_return({
        :auth_token => token,
        :callback_domain => "example.com",
        :use_twilio_digest_auth => true
      })

      request.stub(:fullpath).and_return("/validate/voice")
      request.stub_chain(:headers, :[]).with('HTTP_X_TWILIO_SIGNATURE')
        .and_return(signature)
      post :index, twilio_params

      response.code.should == "200"
    end

    context "with invalid params" do
      before do
        request.stub_chain(:headers, :[]).with('HTTP_X_TWILIO_SIGNATURE')
          .and_return(signature)
        controller.stub(:twilio_config).and_return({
          :auth_token => token,
          :use_twilio_digest_auth => true
        })
      end

      it "returns a 401" do
        get :index, { :foo => 'bar' }
        response.code.should == "401"
        response.body.should == "Twilio request signature verification failed."
      end
    end
  end
end
