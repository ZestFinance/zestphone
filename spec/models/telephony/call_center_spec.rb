require_relative File.join __FILE__, '../../../../app/models/telephony/call_center'

module Telephony
  describe CallCenter do
    before do
      @development_config = CallCenter.load "test", "spec/dummy/config/call_centers.yml"
    end

    describe "#load" do
      it "load a config for a given environment" do
        call_center = @development_config.first
        call_center['name'].should == 'hollywood'
        call_center['host'].should == '192.168.1.1'
      end
    end

    describe "#all" do
      before { CallCenter.load "development" }
      it "retuns all call centers" do
        CallCenter.all.count.should == 2
        CallCenter.all.first.name.should == 'hollywood'
      end
    end

    describe "#find_by_name" do
      it "returns first matching call center" do
        call_center = CallCenter.find_by_name 'other_location'
        call_center.name.should == "other_location"
      end
    end
  end
end
