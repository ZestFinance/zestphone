require 'spec_helper'

module Telephony
  describe PlayableListener do
    describe "#valid?" do
      it "fails without a csr id" do
        listener = build :playable_listener, csr_id: nil

        listener.should_not be_valid
        listener.should have(1).error_on(:csr_id)
      end

      it "fails without a playable id" do
        listener = build :playable_listener, playable_id: nil

        listener.should_not be_valid
        listener.should have(1).error_on(:playable_id)
      end
    end

    describe '.recent' do
      context 'given playable listeners for multiple playables' do
        before do
          playable = create :voicemail
          create :playable_listener,
            playable_id: playable.id,
            created_at: 2.days.ago
          @most_recent_listener = create :playable_listener,
            playable_id: playable.id,
            created_at: 1.day.ago

          @playable_listeners = PlayableListener.recent playable_ids: [playable]
        end

        it 'returns the most recent listener for each playable' do
          @playable_listeners.should_not be_empty
          @playable_listeners[0].should == @most_recent_listener
        end
      end
    end
  end
end

