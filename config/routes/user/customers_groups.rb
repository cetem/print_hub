resources :customers_groups do
  collection do
    get :autocomplete_for_name
    get :global_settlement
  end

  get :settlement, on: :member
end
