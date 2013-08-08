require 'spec_helper'

module Telephony
  module Providers
    describe TwilioProvider do
      before do
        @config = YAML.load_file(Rails.root.join('config', 'twilio.yml'))['test']
        @twilio_provider = TwilioProvider.new @config
      end

      describe '.new' do
        context 'given a Twilio configuration' do
          before do
            @config = {
              account_sid: 'account_sid',
              auth_token: 'auth_token',
              outbound_caller_id: 'outbound_caller_id',
              callback_root: 'callback_root'
            }

            @twilio_provider = TwilioProvider.new @config
          end

          it 'sets its attributes to match that configuration' do
            @twilio_provider.account_sid.should == @config[:account_sid]
            @twilio_provider.auth_token.should == @config[:auth_token]
            @twilio_provider.outbound_caller_id.should == @config[:outbound_caller_id]
            @twilio_provider.callback_root.should == @config[:callback_root]
          end
        end
      end

      describe '#call', :vcr do
        before do
          @call_id = '1'
          @phone_number = '555-555-1234'
          @caller_id = '500-555-0006'

          @call = @twilio_provider.call @call_id, @phone_number, @caller_id
        end

        it 'places a call' do
          @call.should be
        end

        it 'includes a status change callback url' do
          request = VCR
            .current_cassette
            .serializable_hash['http_interactions'][0]['request']
          body = Rack::Utils.parse_nested_query request['body']['string']
          body['StatusCallback'].should =~ %r{calls/#{@call_id}/done$}
        end

        it 'allows the phone to ring for 60 seconds' do
          request = VCR
            .current_cassette
            .serializable_hash['http_interactions'][0]['request']
          body = Rack::Utils.parse_nested_query request['body']['string']
          body['Timeout'].should == '60'
        end
      end

      describe 'when an exception occurs' do
        before do
          @call_id = '1'
          @phone_number = '555-555-1234'
          @caller_id = '500-555-0006'
          @twilio_provider = TwilioProvider.new @config
          @client = @twilio_provider.client
        end

        it 'raises a Telephony::Error::Connection exception and logs the error' do
          @client
            .should_receive(:account)
            .and_raise(::Twilio::REST::RequestError.new(''))

          Rails.logger.should_receive(:error)

          expect do
            @twilio_provider.call @call_id, @phone_number, @caller_id
          end.to raise_error(Telephony::Error::Connection)
        end
      end

      describe '#redirect_to_conference' do
        context 'by default' do
          before do
            call_id = '1'
            call = double 'call'
            call
              .should_receive(:redirect_to)
              .with("#{@config[:callback_root]}/providers/twilio/calls/#{call_id}/join_conference")
            ::Twilio::REST::Client
              .any_instance
              .stub_chain(:account, :calls, :find)
              .and_return(call)
            @ok = @twilio_provider.redirect_to_conference call_id, 'sid'
          end

          it 'should not raise an error' do
            @ok.should be_true
          end
        end

        context 'when trying to redirect a non existing call' do
          before do
            call = double 'call'
            call
              .stub(:redirect_to)
              .and_raise(::Twilio::REST::RequestError.new('something'))
            ::Twilio::REST::Client
              .any_instance
              .stub_chain(:account, :calls, :find)
              .and_return(call)

          end

          it 'raises a Telephony Error' do
            expect {
              @twilio_provider.redirect_to_conference 'call_id', 'sid'
            }.to raise_error(Telephony::Error::Connection)
          end
        end

        context 'when the REST call to twilio times out' do
          before do
            call = double 'call'
            call
              .stub(:redirect_to)
              .and_raise(::Timeout::Error.new('something'))
            ::Twilio::REST::Client
              .any_instance
              .stub_chain(:account, :calls, :find)
              .and_return(call)

          end

          it 'raises a Telephony Error' do
            expect {
              @twilio_provider.redirect_to_conference 'call_id', 'sid'
            }.to raise_error(Telephony::Error::Connection)
          end
        end
      end

      describe '#redirect_to_hold' do
        context 'by default' do
          before do
            call_id = '1'
            call = double 'call'
            call
              .should_receive(:redirect_to)
              .with(/complete_hold/)
            ::Twilio::REST::Client
              .any_instance
              .stub_chain(:account, :calls, :find)
              .and_return(call)
            @ok = @twilio_provider.redirect_to_hold call_id, 'sid'
          end

          it 'returns true' do
            @ok.should be_true
          end
        end

        context 'when trying to redirect a non existing call' do
          before do
            call = double 'call'
            call
              .stub(:redirect_to)
              .and_raise(::Twilio::REST::RequestError.new('something'))

            ::Twilio::REST::Client
              .any_instance
              .stub_chain(:account, :calls, :find)
              .and_return(call)
          end

          it 'raises a Telephony Error' do
            expect {
              @twilio_provider.redirect_to_hold 'call_id', 'sid'
            }.to raise_error(Telephony::Error::Connection)
          end
        end
      end

      describe '#dial_into_conference', :vcr do
        before do
          @call_id = '1'
          @phone_number = '555-555-1238'
          @caller_id = '500-555-0006'

          @twilio_provider.dial_into_conference @call_id, @phone_number, @caller_id
        end

        it 'allows the phone to ring for 15 seconds' do
          request = VCR
            .current_cassette
            .serializable_hash['http_interactions'][0]['request']
          body = Rack::Utils.parse_nested_query request['body']['string']
          body['Timeout'].should == '15'
        end

        it 'places a call to redirect the participant to a conference' do
          request = VCR
            .current_cassette
            .serializable_hash['http_interactions'][0]['request']
          body = Rack::Utils.parse_nested_query request['body']['string']
          body['Url'].should =~ %r{calls/#{@call_id}/join_conference$}
        end
      end

      describe "#buy_number_for_area_code" do
        # NOTE do NOT change the cassette name or it will buy a new number from Twilio
        use_vcr_cassette "buying number for an area code"

        before do
          @area_code = "500"
          @expected_number = "5555559876"

          @number = @twilio_provider.buy_number_for_area_code(@area_code)
        end

        it 'returns nil in case of error' do
          @twilio_provider.should_receive(:buy_number).and_raise(Exception.new)
          number = @twilio_provider.buy_number_for_area_code(@area_code)
          number.should == nil
        end
      end

      describe '#uncallable_number' do
        before do
          @uncallable_number = @twilio_provider.uncallable_number
        end

        it "returns a number that Twilio can't call" do
          @uncallable_number.should == 'this-number-is-not-whitelisted'
        end
      end

      describe '#hangup', :vcr do
        context 'by default' do
          before do
            conversation = create :conversation, caller_id: "5005550006"
            @call = create :call, conversation: conversation
            @call.make!

            ::Twilio::REST::Call.any_instance.should_receive(:hangup)
          end

          it 'hangs up the call' do
            @twilio_provider.hangup @call.sid
          end
        end

        context 'when an exception occurs' do
          before do
            Rails.logger.should_receive(:error)
            ::Twilio::REST::Call.any_instance.should_receive(:hangup)
              .and_raise(StandardError.new('Some error'))
          end

          it "logs the error and returns false" do
            value = @twilio_provider.hangup 'sid'
            value.should be_false
          end
        end
      end

      describe '#dial' do
        context 'by default' do
          before do
            call_id = 1
            call = mock 'call'
            call
              .should_receive(:redirect_to)
              .with("#{@config[:callback_root]}/providers/twilio/calls/#{call_id}/dial")
            ::Twilio::REST::Client
              .any_instance
              .stub_chain(:account, :calls, :find)
              .and_return(call)

            @ret = @twilio_provider.redirect_to_dial call_id, 'sid'
          end

          it 'should not raise an error' do
            @ret.should be_true
          end
        end

        context 'when trying to dial from a non existing call' do
          before do
            call = double 'call'
            call
              .stub(:redirect_to)
              .and_raise(::Twilio::REST::RequestError.new('something'))
            ::Twilio::REST::Client
              .any_instance
              .stub_chain(:account, :calls, :find)
              .and_return(call)
          end

          it 'returns a failure status and a failure message' do
            expect {
              @twilio_provider.redirect_to_dial 'call_id', 'sid'
            }.to raise_error(Telephony::Error::Connection)
          end
        end
      end

      describe '#call_ended?' do
        context 'given the sid of an in progress call' do
          before do
            sid = 'sid'
            stub_request(:get, %r{/Accounts/\w+/Calls/#{sid}.json})
              .to_return(body: { status: 'in-progress' }.to_json)

            VCR.turned_off do
              @call_ended = Telephony.provider.call_ended? sid
            end
          end

          it 'returns false' do
            @call_ended.should be_false
          end
        end

        context 'given the sid of a terminated call' do
          before do
            sid = 'sid'
            stub_request(:get, %r{/Accounts/\w+/Calls/#{sid}.json})
              .to_return(body: { status: 'completed' }.to_json)

            VCR.turned_off do
              @call_ended = Telephony.provider.call_ended? sid
            end
          end

          it 'returns true' do
            @call_ended.should be_true
          end
        end

        context 'when a Twilio::REST::RequestError occurs' do
          before do
            sid = 'sid'
            stub_request(:get, %r{/Accounts/\w+/Calls/#{sid}.json})
              .to_raise(::Twilio::REST::RequestError.new(''))

            Rails.logger.should_not_receive(:error)
            VCR.turned_off do
              @call_ended = Telephony.provider.call_ended? sid
            end
          end

          it 'does not log the error and returns false' do
            @call_ended.should be_false
          end
        end

        context 'when another exception occurs' do
          before do
            sid = 'sid'
            stub_request(:get, %r{/Accounts/\w+/Calls/#{sid}.json})
              .to_raise(StandardError.new('Some error'))

            Rails.logger.should_receive(:error)
            VCR.turned_off do
              @call_ended = Telephony.provider.call_ended? sid
            end
          end

          it 'logs the error and returns false' do
            @call_ended.should be_false
          end
        end

        context 'given the sid of a call without a status' do
          before do
            sid = 'sid'
            stub_request(:get, %r{/Accounts/\w+/Calls/#{sid}.json})
              .to_return(body: { sid: 'sid' }.to_json)

            VCR.turned_off do
              @call_ended = Telephony.provider.call_ended? sid
            end
          end

          it 'returns false' do
            @call_ended.should be_false
          end
        end
      end


      describe "#caller_id_for" do
        use_vcr_cassette "display a local caller id"

        before do
          @area_code = '213'
          @number = '2131234567'
        end

        context "cached area code" do
          before do
            @twilio_provider.should_receive(:incoming_phone_number_from_cache).with(@area_code).and_return(@number)
          end

          it 'uses the number' do
            @twilio_provider.caller_id_for(@area_code).should == @number
          end
        end

        context "existing area code" do
          before do
            @twilio_provider.should_receive(:fetch_existing_incoming_phone_numbers).with(@area_code).and_return(@number)
          end

          it 'reuse the the number' do
            @twilio_provider.caller_id_for(@area_code).should == @number
          end
        end

        context "missing area code" do
          before do
            @twilio_provider.should_receive(:fetch_existing_incoming_phone_numbers).with(@area_code).and_return(nil)
            @twilio_provider.should_receive(:buy_number_for_area_code).with(@area_code).and_return(@number)
          end

          it 'buy the number' do
            @twilio_provider.caller_id_for(@area_code).should == @number
          end
        end
      end
    end
  end
end
