match 'orders/clear_catalog_order' => 'orders#clear_catalog_order', via: :delete
resources :orders do
  get :download_file, on: :member
  post :upload_file, on: :collection
end
