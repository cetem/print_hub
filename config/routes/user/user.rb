resources :users, except: [:destroy] do
  resources :shifts
  get :autocomplete_for_user_name, on: :collection

  member do
    get :avatar, path: '/avatar/:style'
    put :pay_shifts_between
  end
end
