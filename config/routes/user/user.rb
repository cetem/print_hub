resources :users, except: [:destroy] do
  resources :shifts

  collection do
    get :autocomplete_for_user_name 
    get :current_workers
  end

  member do
    patch :pay_shifts_between
  end
end
