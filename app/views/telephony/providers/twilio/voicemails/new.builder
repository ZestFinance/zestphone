xml.instruct!

xml.Response do
  xml.Say "The person at extension #{@child_call.agent.phone_ext} is not available.  At the tone, record your message"
  xml.Record action: providers_twilio_call_voicemail_path(@call, csr_id: @child_call.agent.csr_id)
end
