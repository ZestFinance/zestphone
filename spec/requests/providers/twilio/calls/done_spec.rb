require 'spec_helper'

describe 'When the callee does not answer' do
  before do
    agent = create :agent
    @call = create :connecting_call, agent: agent

    post "/zestphone/providers/twilio/calls/#{@call.id}/done",
      { CallStatus: 'no-answer'}
  end

  it 'sets the call as terminated' do
    @call.reload
    @call.should be_terminated
  end
end

describe 'When the call ends' do
  before do
    agent = create :agent
    @call = create :call, agent: agent
    @recording_url = 'recording_url'
    @recording_duration = 0

    post "/zestphone/providers/twilio/calls/#{@call.id}/done",
      { CallStatus: 'completed',
        RecordingUrl: @recording_url,
        RecordingDuration: @recording_duration }

    @call.reload
  end

  it 'saves the recording of the call' do
    @call.recordings.last.url.should == @recording_url
    @call.recordings.last.duration.should == @recording_duration
  end

  it 'terminates the call' do
    @call.should be_terminated
  end

  it 'returns TwiML saying the caller on the other end has hung up' do
    xml = Nokogiri::XML response.body
    say = xml.at('/Response/Say')
    say.text.should =~ /the caller on the other line has hung up/i
  end
end

describe 'When the call has already not been answered' do
  before do
    agent = create :agent
    @call = create :terminated_call, agent: agent
    @recording_url = 'recording_url'
    @recording_duration = 0
    @call.should_not_receive(:no_answer!)

    post "/zestphone/providers/twilio/calls/#{@call.id}/done",
      { CallStatus: 'no-answer',
        RecordingUrl: @recording_url,
        RecordingDuration: @recording_duration }

    @call.reload
  end

  it 'saves the recording of the call' do
    @call.recordings.last.url.should == @recording_url
    @call.recordings.last.duration.should == @recording_duration
  end
end
