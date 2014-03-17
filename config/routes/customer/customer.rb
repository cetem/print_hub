resources :customers, only: [:new, :create] do
  member do
    get :edit_profile
    patch :update_profile
  end
end
