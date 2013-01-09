resources :orders do
  get :download_file, on: :member
  post :upload_file, on: :collection
end
