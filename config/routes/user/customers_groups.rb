resources :customers_groups do
  get :autocomplete_for_name, on: :collection
  get :settlement, on: :member
end
