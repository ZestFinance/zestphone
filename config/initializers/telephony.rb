# Placeholder for delayed job.
Telephony::DELAYED_JOB = Class.new unless defined?(Telephony::DELAYED_JOB)

# Placeholder for business open hours
Telephony::OFFICE_HOURS = Class.new do
  def self.open?
    true
  end

  def self.open_hours_audio_files(params)
    out = ["http://demo.twilio.com/hellomonkey/monkey.mp3"]
    out.unshift "https://api.twilio.com/cowbell.mp3" if params[:play_zestcash_transition].present?
    out
  end

  def self.closed_hours_audio_files(params)
    ["https://api.twilio.com/cowbell.mp3"]
  end
end unless defined?(Telephony::OFFICE_HOURS)

Telephony::CallCenter.load Rails.env.to_s, Rails.root.to_s + '/config/call_centers.yml'

unless defined?(TWILIO_CONFIG)
  filename = 'config/twilio.yml'
  if File.exists? Rails.root.join(filename)
    twilio_configs = YAML.load_file Rails.root.join(filename)
    TWILIO_CONFIG = twilio_configs[Rails.env]
  else
    TWILIO_CONFIG = nil
  end
end

if TWILIO_CONFIG
  TWILIO_CONFIG.to_options!

  Telephony.provider = Telephony::Providers::TwilioProvider.new TWILIO_CONFIG
  Telephony.hold_music = TWILIO_CONFIG[:hold_music]
  Telephony.wait_music = TWILIO_CONFIG[:wait_music]
else
  Rails.logger.warn "#{filename} does not include config for RAILS_ENV=#{Rails.env}"
end
