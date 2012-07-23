resources :users, except: [:destroy] do
  get :avatar, on: :member, path: '/avatar/:style'
  resources :shifts
end
