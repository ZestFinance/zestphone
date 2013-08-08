require 'spec_helper'

describe Telephony::NumberHelper do
  before do
    @call = mock("some call model")
    @call.extend(Telephony::NumberHelper)
  end

  describe "#normalize_number" do
    it "removes non digit charactors" do
      @call.normalize_number("(213)323-3233").should == "2133233233"
    end

    it "removes the leading 1" do
      @call.normalize_number("1300-300-4000").should == "3003004000"
    end
  end

  describe "#extract_area_code" do
    it "returns the area code" do
      @call.extract_area_code("213-563-5633").should == "213"
    end
  end
end
