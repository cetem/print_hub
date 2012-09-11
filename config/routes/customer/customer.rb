match 'customers/activate/:token' => 'customers#activate',
  as: 'activate_customer', via: :get

resources :customers, only: [:new, :create] do
  member do
    get :edit_profile
    put :update_profile
  end
end
