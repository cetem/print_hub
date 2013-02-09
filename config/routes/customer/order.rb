match 'orders/clear_catalog_order' => 'orders#clear_catalog_order', via: :delete
resources :orders do
  post :upload_file, on: :collection
end
