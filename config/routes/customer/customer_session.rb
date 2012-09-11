resources :customer_sessions, only: [:new, :create] do
  delete :destroy, on: :collection
end
