require 'spec_helper'

module Telephony
  describe CallCentersController do

    before do
      @routes = Engine.routes
    end

    describe '#index' do
      before do
        get :index
      end

      it 'returns a list of the available call centers' do
        response.should be_ok
        response.content_type.should == "application/json"

        call_centers = JSON.parse(response.body)
        call_centers.first['name'].should == 'hollywood'
        call_centers.first['host'].should == '192.168.1.1'
      end
    end
  end
end
