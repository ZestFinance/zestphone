Telephony::Engine.routes.draw do
  namespace :providers do
    namespace :twilio do
      resources :calls do
        member do
          post :connect
          post :child_answered
          post :child_detached
          post :dial
          post :join_conference
          post :done
          post :complete_hold
          post :leave_queue
        end

        resource :voicemail
      end

      resources :musics do
        collection do
          get "hold"
        end
      end

      resources :inbound_calls, only: :create do
        collection do
          get  :wait_music
          post :connect
        end

        member do
          post :enqueue
        end
      end
    end
  end

  namespace :signals do
    namespace :agents do
      resources :presences, only: :create do
        collection do
          post :authenticate
        end
      end
    end
  end

  resources :voicemails

  resources :conversations do
    collection do
      get :counts
      get :search
    end

    member do
      post :hold
      post :resume
    end

    resources :transfers, only: :create
  end

  resources :playable_listeners, only: [:create, :index] do
    collection do
      get :recent
    end
  end

  namespace :inbound do
    delete '/front' => 'conversation_queues#front'
  end

  resources :agents, only: [:index, :update] do
    collection do
      get "/show_by_csr_id/:csr_id" => "agents#show_by_csr_id"
    end

    member do
      put :status
    end
  end

  resources :widget, only: :index

  resources :twilio_client, only: :index do
    collection do
      get :token
    end
  end

  resources :call_centers, only: :index
end
