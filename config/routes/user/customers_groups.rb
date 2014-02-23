resources :customers_groups do
  get :autocomplete_for_name, on: :collection
end
