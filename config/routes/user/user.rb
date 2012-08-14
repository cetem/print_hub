resources :users, except: [:destroy] do
  get :avatar, on: :member, path: '/avatar/:style'
  get :autocomplete_for_user_name, on: :collection
end
