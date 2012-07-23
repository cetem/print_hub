resources :tags do
  resources :documents, only: [:index]
end
