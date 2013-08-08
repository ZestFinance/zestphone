require 'spec_helper'

module Telephony
  module Jobs
    describe PusherEvent do
      describe '#perform' do
        before do
          event = {
            channel: 'channel',
            name: 'name',
            data: 'data'
          }

          Telephony::PusherEventPublisher.should_receive(:push)
            .with(event)

          @job = PusherEvent.new(event)
        end

        it 'publishes an agent status change' do
          @job.perform
        end
      end

      describe '#failure' do
        before do
          @job = PusherEvent.new({})

          ActiveSupport::Notifications.should_receive(:instrument)
          Rails.logger.should_receive(:error)
        end

        it "notifies an error" do
          @job.failure
        end
      end
    end
  end
end
