require 'spec_helper'

module Telephony
  describe WidgetController do
    render_views

    before do
      @routes = Engine.routes
    end

    describe '#index' do
      before do
        get :index
      end

      it 'returns the telephony widget asset path' do
        response.should be_ok
        response.content_type.should == "application/json"

        data = JSON.parse(response.body)
        data['path'].should == "/assets/telephony/widget.js"
      end
    end
  end
end
