xml.instruct!

xml.Response do
  @files.each do |file|
    xml.Play file
  end
  xml.Redirect enqueue_providers_twilio_inbound_call_path(@conversation)
end
