resources :shifts, except: :new do
  get :json_paginate, on: :collection
end
