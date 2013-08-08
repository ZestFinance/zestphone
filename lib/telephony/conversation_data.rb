module Telephony
  class ConversationData
    def self.filter(params = {})
      conversations = Conversation.scoped

      if params[:state]
        conversations = conversations.where(state: params[:state])
      end

      if params[:since]
        since = params[:since].to_datetime
        conversations = conversations.where created_at: since..Time.now
      end

      conversations.all
    end

    def self.counts(args = {})
      # FIXME: Add pagination support
      conversation_counts = Conversation
        .group(:initiator_id)
        .where('initiator_id IS NOT NULL')
      conversation_counts = if args[:start_date].present? &&
        args[:end_date].present?
        conversation_counts.where('created_at BETWEEN ? and ?',
                        DateTime.parse(args[:start_date]).utc,
                        DateTime.parse(args[:end_date]).utc)
      else
        conversation_counts.where('created_at > ?', 30.days.ago)
      end.count
    end

    def self.search(args = {})
      conversations = Conversation.scoped
        .includes(:events, calls: [:recordings, :voicemail])
        .order("telephony_conversations.created_at")
          .reverse_order
        .page(args[:page])
        .per(10)

      if args[:csr_id].present?
        agent = Agent.find_by_csr_id args[:csr_id]
        agent_id = agent ? agent.id : -1
        conversations = conversations.where("telephony_conversations.id in (#{Call.select(:conversation_id).where(agent_id: agent_id).to_sql})")
      end

      if args[:q].present?
        query = args[:q].to_s.strip
        condition = "telephony_conversations.loan_id = ? OR telephony_conversations.id = ? OR telephony_calls.number like ?"
        subquery = Conversation.select("telephony_conversations.id").joins(:calls).where(condition, query, query, "%#{query}%").to_sql
        conversations = conversations.where("telephony_conversations.id in (#{subquery})")
      end

      if args[:start_date].present?
        conversations = conversations.where('telephony_conversations.created_at >= ?',
          DateTime.parse(args[:start_date]).utc)
      end

      if args[:end_date].present?
        conversations = conversations.where('telephony_conversations.created_at <= ?',
          DateTime.parse(args[:end_date]).utc)
      end

      conversations
    end
  end
end
