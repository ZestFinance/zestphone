module Telephony
  class PusherEventPublisher
    def self.push(event)
      channel, name, data = event.values_at :channel, :name, :data
      Pusher[channel].trigger(name, data)
    end

    def self.publish(event)
      if Telephony::DELAYED_JOB.respond_to?(:enqueue)
        job = Jobs::PusherEvent.new(event)
        DELAYED_JOB.enqueue(job)
      else
        push event
      end
    end

    def self.queue_change(size, event_id, agent=nil)
      publish channel: agent.nil? ? "csrs" : "csrs-#{agent.csr_id}",
        name: 'QueueChange',
        data: {
          size: size,
          event_id: event_id
        }
    end
  end
end
