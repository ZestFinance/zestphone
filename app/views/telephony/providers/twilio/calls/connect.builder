xml.instruct!

xml.Response do
  if @connecting_call.whitelisted_number?
    xml.Dial action: child_detached_providers_twilio_call_path(@call), record: true, callerId: @call.conversation.caller_id do
      xml.tag! twiml_word_for(@connecting_call),
        @connecting_call.number,
        url: child_answered_providers_twilio_call_path(@connecting_call)
    end
  else
    xml.Say 'The number you are trying to call is not whitelisted'
  end
end
