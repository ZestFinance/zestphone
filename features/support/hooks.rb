timeout = ENV['TEARDOWN_TIMEOUT'] ? ENV['TEARDOWN_TIMEOUT'].to_i : 20
puts "=== Setting default teardown time to #{timeout} seconds ==="

Before '@teardown_timeout' do
  puts "=== Waiting for remaining Pusher callbacks ==="
  sleep timeout # wait until Pusher decides that we're offline
end

After '@teardown_timeout' do
  puts "=== Waiting for remaining Twilio callbacks ==="
  sleep timeout # wait for Twilio callbacks about dead calls
end
