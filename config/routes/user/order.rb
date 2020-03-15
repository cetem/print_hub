resources :orders, only: [:index, :show, :destroy] do
  member do
    get :download_file
    patch :mark_as_ready
  end
  collection do
    post :upload_file
    get :new_for_customer
    post :create_for_customer
  end
end
