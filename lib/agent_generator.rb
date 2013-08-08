##
# Generate bunch of fake Agents in development database
#

class AgentGenerator
  def self.generate
    return if Rails.env.production?

    require 'faker'

    100.times do
      opts = {
        name: Faker::Name.name,
        csr_id: rand(10000),
        csr_type: ["A", "B"].sample,
        phone_number: Faker::PhoneNumber.phone_number,
        phone_ext: rand(500),
        status: ["available", "offline", "on_a_call", "not_available"].sample
      }

      Telephony::Agent.create opts
    end
  end
end
