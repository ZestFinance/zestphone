require 'spec_helper'

module Telephony
  describe PlayableListenersController do
    before do
      @routes = Engine.routes
    end

    describe '#index' do
      context 'when valid params' do
        let(:listener) { create :playable_listener }

        before do
          get :index, { playable_id: listener.playable_id }
        end

        it 'returns success' do
          response.status.should == 200
        end

        context 'given a successful response' do
          before do
            @listeners = JSON.parse response.body
            @listener = @listeners.first
          end

          it 'returns listeners' do
            @listeners.length.should == 1
          end

          it 'returns some field for each listener' do
            @listener['id'].should == listener.id
            @listener['playable_id'].should == listener.playable_id
            @listener['csr_id'].should == listener.csr_id
            Time.parse(@listener['created_at']).to_i.should == listener.created_at.to_i
          end
        end
      end

      context 'order by most recent' do
        before do
          @last = create :playable_listener, playable_id:1,  created_at: 1.day.ago
          @first = create :playable_listener, playable_id:1,  created_at: 1.hour.ago
          @middle = create :playable_listener, playable_id:1,  created_at: 3.hours.ago

          get :index, { playable_id: 1 }
        end

        it 'returns results order by most recent' do
          res = JSON response.body
          res[0]['id'].should == @first.id
          res[1]['id'].should == @middle.id
          res[2]['id'].should == @last.id
        end
      end

      context 'when invalid params' do
        it 'returns a response error' do
          get :index

          response.status.should == 400
          response.message.should == "Bad Request"
          response.body.should be_blank
        end
      end
    end

    describe '#recent' do
      context 'when valid params' do
        before do
          create_list :playable_listener, 2, playable_id: 1
          create_list :playable_listener, 2, playable_id: 2
          create_list :playable_listener, 1, playable_id: 3
        end

        it 'returns the most recent playable listener for each playable id' do
          get :recent, { playable_ids: [1, 2] }

          listeners = JSON.parse response.body
          listeners.count.should == 2
          listeners.map{ |e| e['playable_id'] }.should == [1, 2]
        end

        it 'returns only existing listeners' do
          get :recent, { playable_ids: [1, 2, 3, 4 ,5] }

          listeners = JSON.parse response.body
          listeners.count.should == 3
          listeners.map{ |e| e['playable_id'] }.should == [1, 2, 3]
        end
      end
    end

    describe '#create' do
      context 'with valid params' do
        before do
          create :playable_listener, { playable_id: 1, csr_id: 2 }
        end

        context 'given a new playable listener record' do
          before do
            post :create, { playable_id: 1, csr_id: 102 }
          end

          it 'returns success' do
            response.status.should == 201
          end

          it 'creates a new record' do
            PlayableListener.count.should == 2
          end

          it 'returns the new playable listener' do
            new_listener = PlayableListener.last

            listener = JSON.parse response.body
            listener['id'].should == new_listener.id
            listener['playable_id'].should == new_listener.playable_id
            listener['csr_id'].should == new_listener.csr_id
            Time.parse(listener['created_at']).to_i.should == new_listener.created_at.to_i
          end

        end
      end

      context 'with invalid params' do
        it 'returns a response error' do
          post :create

          response.status.should == 400
          response.message.should == "Bad Request"
          response.body.should be_blank
        end
      end
    end

  end
end
