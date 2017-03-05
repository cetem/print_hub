resources :customers, only: [:new, :create] do
  member do
    get :edit_profile
    patch :update_profile
    get :credits
  end
end
get 'customers/:customer_id/credits/:id' => 'customers#historical_credit', as: 'historical_credit_customer'
