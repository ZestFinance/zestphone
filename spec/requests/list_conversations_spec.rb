require 'spec_helper'

describe 'List all conversations' do
  context 'when there are conversations in the system' do
    before do
      create_list :terminated_conversation, 3
      create_list :connecting_conversation, 2
      create_list :in_progress_conversation, 4
    end

    context 'and given no filtering parameters' do
      before do
        xhr :get, '/zestphone/conversations'
      end

      it 'returns all conversations and their details' do
        json = JSON response.body
        json.should have(9).items
      end
    end

    context 'and given filter parameters' do
      before do
        xhr :get, '/zestphone/conversations', state: 'terminated'
      end

      it 'returns only conversations that match those filters' do
        json = JSON response.body
        json.should have(3).items
      end
    end
  end
end
