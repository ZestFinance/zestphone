module Telephony
  class Voicemail < Playable
    attr_accessible :csr_id

    validates :csr_id, presence: true

    def self.filter(args)
      paged = page args[:page]
      if args[:csr_id].present?
        paged = paged.where csr_id: args[:csr_id]
      end
      paged.per 10
    end

    def self.most_recent
      order("created_at DESC")
    end

    def as_json(attributes = {})
      super attributes.merge(only: [:id, :url, :created_at, :duration],
                             methods: %w(loan_id transferer_id transferee_id))
    end

    def loan_id
      call.conversation.loan_id
    end

    def transferer_id
      call.conversation.initiator_id
    end

    def transferee_id
      csr_id
    end
  end
end
