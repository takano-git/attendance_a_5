Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users do
    collection { post :import }
    # patch 'update_basic_info'
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month' 
      patch 'applies/update_one_month' # /users/:id/applies/update_one_month(.:format)
    end
    resources :attendances, only: :update
    
    resources :applies, only: :update  # /users/:user_id/applies/:id(.:format)
  end
end
