resources :customers do
  resources :prints, only: [:index]
  resources :bonuses, only: [:index]

  member do
    get :credit_detail
    patch :pay_off_debt
    patch :pay_month_debt
    patch :manual_activation
    put :use_rfid
    post :assign_rfid
  end
end
