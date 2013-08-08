Rails.application.routes.draw do
  mount Telephony::Engine => "/zestphone"

  root to: 'widget_host#index'
end
