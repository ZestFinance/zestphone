require 'spec_helper'

describe 'Joining a conference' do

  context "given an 'in_progress' conversation" do
    before do
      @conversation = create :in_progress_conversation_with_calls
      @call = @conversation.active_agent_leg
      @original_conversation_state = @call.conversation.state

      post "/zestphone/providers/twilio/calls/#{@call.id}/join_conference"

      @call.reload
    end

    it "updates the call's state to 'in_conference'" do
      @call.should be_in_conference
    end

    it 'returns TwiML for joining a conference' do
      @call.should join_conference
    end

    it 'does not change the conversation state' do
      @call.conversation.state.should == @original_conversation_state
    end
  end

  context "given an 'initiating_resume' conversation" do
    before do
      @conversation = create :initiating_resume_conversation
      create :active_agent_leg, :state => 'in_conference', :conversation => @conversation
      call = create :call, :state => 'in_progress_hold', :conversation => @conversation

      post "/zestphone/providers/twilio/calls/#{call.id}/join_conference"
    end

    it "triggers 'complete_resume' event on the conversation" do
      @conversation.reload.should be_in_progress
    end
  end

  context "given an 'initiating_hold' conversation" do
    before do
      @conversation = create :initiating_hold_conversation
      agent_call = create :active_agent_leg, :state => 'in_progress', :conversation => @conversation
      create :call, :state => 'in_progress_hold', :conversation => @conversation

      post "/zestphone/providers/twilio/calls/#{agent_call.id}/join_conference"
    end

    it "triggers 'complete_hold' event on the conversation" do
      @conversation.reload.should be_in_progress_hold
    end
  end
end
