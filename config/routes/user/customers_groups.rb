resources :customers_groups do
  collection do
    get :autocomplete_for_name
    get :global_settlement
  end

  member do
    get :settlement
    put :pay_between
  end
end
