require 'spec_helper'

module Telephony
  describe EventObserver do
    before do
      ActiveRecord::Base.observers.enable 'Telephony::EventObserver'
      EventObserver.instance
    end

    describe "#after_create" do
      let(:event) { build(:event) }

      it "asks its event to publish itself" do
        event.should_receive(:publish)
        event.save!
      end
    end
  end
end
