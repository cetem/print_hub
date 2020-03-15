resources :orders, only: [:index, :show, :destroy] do
  get :download_file, on: :member
  collection do
    post :upload_file
    get :new_for_customer
    post :create_for_customer
  end
end
