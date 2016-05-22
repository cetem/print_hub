resources :shifts, except: :new do
  collection do
    get :json_paginate
    get :export_to_drive
  end
end
