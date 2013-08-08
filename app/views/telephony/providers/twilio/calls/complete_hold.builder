xml.instruct!

xml.Response do
  xml.Enqueue 'hold',
    action: leave_queue_providers_twilio_call_path(@call)
end
