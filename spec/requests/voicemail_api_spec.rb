require 'spec_helper'

describe 'GET /voicemails' do
  before do
    create_list :voicemail, 3

    get '/zestphone/voicemails'
  end

  it 'returns all voicemails as JSON' do
    json = JSON response.body
    voicemails = json['items']
    voicemails.should have(Telephony::Voicemail.count).voicemails
    voicemails.each do |voicemail|
      %w(id
         url
         created_at
         duration
         loan_id
         transferer_id
         transferee_id).each do |attribute|
        voicemail.should include(attribute)
      end
    end
    json['total_count'].should == Telephony::Voicemail.count
  end

end

describe "GET /voicemails ordering" do
  it 'orders voicemails by most recent' do
    voicemails = create_list :voicemail, 3
    voicemails[0].update_attribute(:created_at, 100.days.ago)
    voicemails[1].update_attribute(:created_at, 3.days.ago)
    voicemails[2].update_attribute(:created_at, 20.days.ago)

    get '/zestphone/voicemails'

    json = JSON response.body
    json["items"].map { |v| v["id"] }.should == [voicemails[1].id, voicemails[2].id, voicemails[0].id]
  end
end

describe 'GET /voicemails?csr_id=' do
  before do
    voicemails = create_list :voicemail, 3
    @csr_id = voicemails.first.csr_id

    get "/zestphone/voicemails?csr_id=#{@csr_id}"
  end

  it 'returns only voicemails left for the CSR as JSON' do
    json = JSON response.body
    items = json['items']
    items.should have(1).voicemail
    items[0]['transferee_id'].should == @csr_id
  end
end
