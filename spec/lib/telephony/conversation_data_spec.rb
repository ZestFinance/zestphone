require 'spec_helper'

module Telephony
  describe ConversationData do
    describe '.filter' do
      before do
        create :conversation, created_at: 5.days.ago
        create_list :terminated_conversation, 2, created_at: 4.days.ago
        create :terminated_conversation
        create_list :in_progress_conversation, 3
        create :connecting_conversation
      end

      context 'given no parameters' do
        it 'returns all conversations' do
          ConversationData.filter.should have(8).items
        end
      end

      context 'given a state parameter' do
        it 'returns conversations with that state' do
          ConversationData.filter(state: 'terminated').should have(3).items
        end
      end

      context 'given a since parameter' do
        it 'returns all conversations that were created after that date' do
          ConversationData.filter(since: 2.days.ago.to_param).should have(5).items
        end
      end

      context 'given a combination of parameters' do
        it 'returns all conversations that match all parameters' do
          ConversationData.filter(since: 2.days.ago.to_param, state: 'terminated').should have(1).item
        end
      end

      context 'any other parameters' do
        it 'ignores them' do
          ConversationData.filter(foo: 'bar').should have(8).items
        end
      end
    end

    describe '.search' do
      context 'by default' do
        before do
          4.times do |n|
            create :conversation, created_at: n.days.from_now
          end
          create :call_with_recording, conversation: Conversation.last
          create :call_with_recording, conversation: Conversation.last
          create :conversation_connect_event, conversation: Conversation.last

          @conversations = ConversationData.search
          @calls  = @conversations.first.calls
          @events  = @conversations.first.events
          @recordings = @calls.first.recordings
        end

        it 'returns conversations, events, calls and recordings' do
          @conversations.count.should == 4
          @calls.count.should == 2
          @events.count.should == 1
          @recordings.count.should == 1
        end

        it 'returns conversations paginated' do
          @conversations.should respond_to(:total_pages)
        end

        it 'returns call most recently created first' do
          @conversations.should have_at_least(2).calls
          @conversations.each_with_index do |call, index|
            if @conversations[index.succ].present?
              call.created_at.should be > @conversations[index.succ].created_at
            end
          end
        end
      end

      context 'given a csr id' do
        before do
          agent = create :agent, csr_id: 321
          conversation = create :conversation
          create :conversation
          create :conversation_connect_event, conversation: conversation

          create :call_with_recording,
            conversation: conversation,
            agent: agent

          @conversations = ConversationData.search csr_id: 321
        end

        it 'returns only their conversations' do
          @conversations.count.should == 1
        end
      end

      context 'given query with a loan id value' do
        before do
          create :outbound_conversation, loan_id: 123
          create :outbound_conversation, loan_id: 123
          create :outbound_conversation

          @conversations = ConversationData.search q: 123
        end

        it 'returns only conversations with that exact loan id' do
          @conversations.count.should == 2
        end
      end

      context 'given query with a phone number value' do
        before do
          conversation = create :conversation
          create :call,
            conversation: conversation,
            number: '555-555-1111'
          create :call,
            conversation: conversation,
            number: '333-333-1111'
          create :conversation

          @conversations = ConversationData.search q: '555-555-1111'
        end

        it 'returns only conversations with that phone number' do
          @conversations.count.should == 1
          @conversations.first.calls.size.should == 2
        end
      end

      context 'given query with a conversation id value' do
        before do
          create :outbound_conversation
          create :outbound_conversation
          @find_me = create :outbound_conversation

          @conversations = ConversationData.search q: @find_me.id
        end

        it 'returns only conversations with that id' do
          @conversations.should == [@find_me]
        end
      end

      context 'given query with a phone number and an agent csr id' do
        before do
          agent = create :agent, csr_id: 123
          conversation = create :conversation
          create :call,
            conversation: conversation,
            number: '555-555-1111',
            agent: agent
          create :call,
            conversation: conversation,
            number: '333-333-1111'
          other_conversation = create :conversation
          create :call,
            conversation: other_conversation,
            number: '555-555-1111'


          @conversations = ConversationData.search q: '555-555-1111', csr_id: 123
        end

        it 'returns only conversations with that phone number and agent csr id' do
          @conversations.count.should == 1
          @conversations.first.calls.size.should == 2
        end
      end

      context 'given a datetime range' do
        before do
          start_date = Time.utc(2012, 12, 2, 19, 30, 0).to_s
          end_date = Time.utc(2012, 12, 11, 19, 30, 0).to_s

          create :conversation,
            created_at: Time.utc(2012, 12, 1, 19, 30, 0)
          create :conversation,
            created_at: Time.utc(2012, 12, 3, 5, 31, 0)
          create :conversation,
            created_at: Time.utc(2012, 12, 10, 20, 31, 0)
          create :conversation,
            created_at: Time.utc(2012, 12, 11, 0, 32, 0)

          @conversations = ConversationData.search start_date: start_date,
            end_date: end_date
        end

        it 'returns conversations in a datetime range' do
          @conversations.count.should == 3
        end
      end

      context 'given a start date' do
        before do
          start_date = Time.utc(2012, 12, 11, 0, 32, 0).to_s

          create :conversation,
            created_at: Time.utc(2012, 12, 1, 19, 30, 0)
          create :conversation,
            created_at: Time.utc(2012, 12, 3, 5, 31, 0)
          create :conversation,
            created_at: Time.utc(2012, 12, 10, 20, 31, 0)
          create :conversation,
            created_at: Time.utc(2012, 12, 11, 0, 32, 0)

          @conversations = ConversationData.search start_date: start_date
        end

        it 'returns conversations from that date until now' do
          @conversations.count.should == 1
        end
      end

      context 'given a page' do
        before do
          create_list :call, 3

          @page = 2
          @conversations = ConversationData.search page: @page
        end

        it 'returns that page of conversations' do
          @conversations.current_page.should == @page
        end
      end
    end

    describe '.counts' do
      before do
        Timecop.travel(Time.local(2012, 12, 10, 19, 30, 0))
      end

      context 'by default' do
        before do
          FactoryGirl.create_list :conversation, 2, :initiator_id => 1
          FactoryGirl.create_list :conversation, 3, :initiator_id => 2
          conversation_without_an_initiator = FactoryGirl.create :conversation,
            :initiator_id => nil

          FactoryGirl.create_list :conversation, 1, :initiator_id => 3
          FactoryGirl.create :conversation,
            :initiator_id => 3,
            :created_at => 31.days.ago

          @counts = ConversationData.counts
        end

        it 'returns the total number of conversations in the last 30 days per agent' do
          @counts.keys.sort.should == [1, 2, 3]
        end
      end

      context 'given a datetime range' do
        before do
          start_date = 1.week.ago.strftime('%m/%d/%Y 00:00:00 PST')
          end_date = Date.today.strftime('%m/%d/%Y 23:59:59 PST')
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 1, 19, 30, 0),
                             :initiator_id => 5
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 3, 5, 31, 0),
                             :initiator_id => 10
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 10, 20, 31, 0),
                             :initiator_id => 20
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 11, 0, 32, 0),
                             :initiator_id => 30

          @counts = ConversationData.counts :start_date => start_date,
            :end_date => end_date
        end

        it 'returns the total number of conversations in the date range per agent' do
          @counts.should == { 20 => 1, 30 =>1 }
        end
      end

      context 'given a datetime but without time zone' do
        before do
          start_date = 1.week.ago.strftime('%m/%d/%Y 00:00:00')
          end_date = Date.today.strftime('%m/%d/%Y 00:00:00')
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 1, 19, 30, 0),
                             :initiator_id => 5
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 3, 5, 31, 0),
                             :initiator_id => 10
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 10, 20, 31, 0),
                             :initiator_id => 20
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 11, 0, 32, 0),
                             :initiator_id => 30

          @counts = ConversationData.counts :start_date => start_date,
                                        :end_date => end_date
        end

        it 'uses treat the default timezone as UTC and returns the total number of conversations in the date range per agent' do
          @counts.should == { 10 =>1 }
        end
      end


      context 'given a date only range' do
        before do
          start_date = 1.week.ago.strftime('%m/%d/%Y')
          end_date = Date.today.strftime('%m/%d/%Y')
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 1, 19, 30, 0),
                             :initiator_id => 5
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 3, 5, 31, 0),
                             :initiator_id => 10
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 9, 23, 50, 40),
                             :initiator_id => 20
          FactoryGirl.create :conversation,
                             :created_at => Time.utc(2012, 12, 11, 0, 32, 0),
                             :initiator_id => 30

          @counts = ConversationData.counts :start_date => start_date,
                                        :end_date => end_date
        end

        it 'uses treat the default timezone as UTC and returns the total number of conversations in the date range per agent' do
          @counts.should == { 10 =>1, 20 => 1}
        end
      end

      after do
        Timecop.return
      end
    end
  end
end
