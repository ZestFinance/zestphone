xml.instruct!

xml.Response do
  if @child_call.whitelisted_number?
    xml.Dial method: 'POST', action: child_detached_providers_twilio_call_path(@call), record: true, timeout: 15 do
      xml.tag! twiml_word_for(@child_call),
        @child_call.number,
        url: child_answered_providers_twilio_call_path(@child_call)
    end
  else
    xml.Say 'The number you are trying to call is not whitelisted'
  end
end

