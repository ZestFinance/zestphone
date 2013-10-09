require 'spec_helper'

describe Telephony do
  describe '.whitelisted?' do
    context 'when using a whitelist' do
      before do
        @old_whitelist = Telephony.whitelist
        @whitelisted_number = '1234567890'
        Telephony.whitelist = [@whitelisted_number]
      end

      after do
        Telephony.whitelist = @old_whitelist
      end

      context 'and given a whitelisted number' do
        before do
          @whitelisted = Telephony.whitelisted? @whitelisted_number
        end

        it 'returns true' do
          @whitelisted.should be_true
        end
      end

      context 'and given a whitelisted number in a custom format' do
        before do
          formatted_whitelisted_number = '(123) 456-7890'
          Telephony.whitelist = [formatted_whitelisted_number.gsub(/\D/, '')]
          @whitelisted = Telephony.whitelisted? formatted_whitelisted_number
        end

        it 'returns true' do
          @whitelisted.should be_true
        end
      end

      context 'and given a whitelisted number with a leading country code' do
        before do
          @whitelisted = Telephony.whitelisted? "+1#{@whitelisted_number}"
        end

        it 'returns true' do
          @whitelisted.should be_true
        end
      end

      context 'and given a non-whitelisted number' do
        before do
          @whitelisted = Telephony.whitelisted? '1'
        end

        it 'returns false' do
          @whitelisted.should be_false
        end
      end

      context 'that contains formatted numbers' do
        before do
          @formatted_number = '(123) 456-7890'
          Telephony.whitelist = [@formatted_number]
        end

        context 'and given an unformatted whitelisted number' do
          before do
            @whitelisted = Telephony.whitelisted? @formatted_number.gsub(/\D/, '')
          end

          it 'returns true' do
            @whitelisted.should be_true
          end
        end
      end
    end

    context 'when not using a whitelist' do
      before do
        @old_whitelist = Telephony.whitelist
        Telephony.whitelist = nil

        @whitelisted = Telephony.whitelisted? '1234567890'
      end

      after do
        Telephony.whitelist = @old_whitelist
      end

      it 'returns true' do
        @whitelisted.should be_true
      end
    end
  end

  describe '.americanize' do
    it 'unformats a formatted number' do
      Telephony.americanize('(123) 456-7890').should == '1234567890'
    end

    it 'does nothing to an unformatted number' do
      Telephony.americanize('1234567890').should == '1234567890'
    end
  end
end

