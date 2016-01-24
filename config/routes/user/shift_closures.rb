resources :shift_closures do
  get :printer_counter, on: :collection
  patch :update_comment, on: :member
end
