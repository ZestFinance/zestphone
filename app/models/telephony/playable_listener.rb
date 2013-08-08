module Telephony
  class PlayableListener < Base
    attr_accessible :playable_id, :csr_id
    validates :playable_id, presence: true
    validates :csr_id, presence: true

    def self.filter params
      listeners = self

      if params[:playable_id]
        listeners = listeners.where({ playable_id: params[:playable_id] })
      end

      if params[:csr_id]
        listeners = listeners.where({ csr_id: params[:csr_id] })
      end

      listeners
        .order("created_at DESC")
        .page(params[:page])
        .per(params[:per])
    end

    def self.recent params
      find_by_sql [<<-EOS, params[:playable_ids]]
        SELECT *
        FROM (SELECT *
              FROM telephony_playable_listeners
              WHERE playable_id IN (?)
              ORDER BY created_at DESC) AS playable_listeners
        GROUP BY playable_listeners.playable_id
      EOS
    end

    def self.register params
      create({
        playable_id: params[:playable_id],
        csr_id: params[:csr_id]
      })
    end
  end
end
