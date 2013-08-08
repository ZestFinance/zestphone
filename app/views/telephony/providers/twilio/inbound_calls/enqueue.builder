xml.instruct!

xml.Response do
  xml.Enqueue 'inbound',
              action: leave_queue_providers_twilio_call_path(@call),
              waitUrlMethod: 'GET',
              waitUrl: wait_music_providers_twilio_inbound_calls_path
end
