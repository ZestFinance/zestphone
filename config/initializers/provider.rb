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
  Telephony.provider = Telephony::Providers::TwilioProvider.new TWILIO_CONFIG
else
  Rails.logger.warn "#{filename} does not include config for RAILS_ENV=#{Rails.env}"
end
