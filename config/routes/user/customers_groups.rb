resources :customers_groups do
  collection do
    get :autocomplete_for_name
    get :global_settlement
    put :global_pay_between
  end

  member do
    get :settlement
    put :pay_between
  end
end
