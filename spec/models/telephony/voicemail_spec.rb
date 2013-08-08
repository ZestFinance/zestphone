require 'spec_helper'

module Telephony
  describe Voicemail do
    describe "#valid?" do
      before do
        @voicemail = build :voicemail, csr_id: nil
      end

      it "fails without a csr id" do
        @voicemail.should_not be_valid
        @voicemail.should have(1).error_on(:csr_id)
      end
    end

    describe '#as_json' do
      before do
        @voicemail = create :voicemail

        @as_json = @voicemail.as_json
      end

      it 'includes its id' do
        @as_json['id'].should == @voicemail.id
      end

      it "includes its conversations' loan id" do
        @as_json['loan_id'].should == @voicemail.call.conversation.loan_id
      end

      it 'includes its creation timestamp' do
        @as_json['created_at'].should == @voicemail.created_at
      end

      it 'includes its duration' do
        @as_json['duration'].should == @voicemail.duration
      end

      it 'includes its url' do
        @as_json['url'].should == @voicemail.url
      end

      it "includes its transferer's id" do
        @as_json['transferer_id'].should == @voicemail.call.conversation.initiator_id
      end

      it "includes its transferee's id" do
        @as_json['transferee_id'].should == @voicemail.csr_id
      end
    end

    describe '.filter' do
      context 'by default' do
        before do
          @page = 1

          @voicemails = Voicemail.filter page: @page
        end

        it 'returns the given page of voicemails' do
          @voicemails.current_page.should == @page
        end

        it 'includes the total count of voicemails' do
          @voicemails.total_count.should == Voicemail.count
        end
      end

      context 'given a CSR id' do
        before do
          voicemails = create_list :voicemail, 3
          @csr_id = voicemails.first.csr_id

          @voicemails = Voicemail.filter csr_id: @csr_id
        end

        it 'returns only voicemails left for that CSR' do
          @voicemails.should_not be_empty
          @voicemails.each do |voicemail|
            voicemail.transferee_id.should == @csr_id
          end
        end
      end
    end

    describe '.most_recent' do
      it "orders by created_at DESC" do
        voicemails = create_list :voicemail, 3
        voicemails[0].update_attribute(:created_at, 100.days.ago)
        voicemails[1].update_attribute(:created_at, 3.days.ago)
        voicemails[2].update_attribute(:created_at, 20.days.ago)
        Voicemail.most_recent.all.should == [voicemails[1], voicemails[2], voicemails[0]]
      end
    end
  end
end
