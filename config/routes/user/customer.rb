resources :customers do
  resources :prints, only: [:index]
  resources :bonuses, only: [:index]

  member do
    get :credit_detail
    put :pay_off_debt
    put :pay_month_debt
  end
end
