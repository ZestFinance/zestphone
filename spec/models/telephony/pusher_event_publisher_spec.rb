require 'spec_helper'

module Telephony
  describe PusherEventPublisher do
    describe ".publish", :vcr do
      let(:event) do
        {
          channel: 'test',
          name: 'test_event',
          data: { key1: 'value' }
        }
      end

      it "queues the event if using delayed_jobs" do
        DELAYED_JOB.should_receive(:enqueue)
        PusherEventPublisher.publish({})
      end

      it "asks Pusher to publish the event" do
        VCR.use_cassette "Pusher to publish the event", match_requests_on: [:path] do
          PusherEventPublisher.publish(event)

          request = VCR.current_cassette.serializable_hash['http_interactions'][0]['request']

          channel, name, data = event.values_at :channel, :name, :data
          body = JSON request['body']['string']
          body.should include('channels' => [channel])
          body.should include('name' => name)

          request_data = JSON body['data']
          request_data.should == data.stringify_keys
        end
      end
    end
  end
end
