resources :documents do
  get :autocomplete_for_tag_name, on: :collection

  member do
    get :barcode
    post :add_to_next_print
    delete :remove_from_next_print
  end
end
