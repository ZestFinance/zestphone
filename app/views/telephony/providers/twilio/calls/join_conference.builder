xml.instruct!

xml.Response do
  xml.Dial action: done_providers_twilio_call_path(@call), record: @call.recorded? do
    xml.Conference "conference-#{@call.conversation_id}", beep: false
  end
end
