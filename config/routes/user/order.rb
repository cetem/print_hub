resources :orders, only: [:index, :show, :destroy] do
  get :download_file, on: :member
end
