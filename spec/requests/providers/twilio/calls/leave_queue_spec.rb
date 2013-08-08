require 'spec_helper'

describe 'When the caller hangs up' do
  before do
    @call = create :call

    post "/zestphone/providers/twilio/calls/#{@call.id}/leave_queue",
      { QueueResult: "hangup" }
  end

  it 'sets the call as terminated' do
    @call.reload
    @call.should be_terminated
  end
end

describe 'When Twilio fails to enqueue the caller call' do
  before do
    @call = create :call
    Rails.logger.should_receive(:error)

    post "/zestphone/providers/twilio/calls/#{@call.id}/leave_queue",
      { QueueResult: "error" }
  end

  it 'sets the call as terminated and logs the error' do
    @call.reload
    @call.should be_terminated
  end
end

describe 'When the caller is taken from the queue' do
  before do
    @call = create :call

    post "/zestphone/providers/twilio/calls/#{@call.id}/leave_queue",
      { QueueResult: "redirected" }
  end

  it 'does not change the call state' do
    @call.should be_not_initiated
  end
end

