resources :documents do
  collection do
    get :autocomplete_for_tag_name
    get :generate_barcodes_range
    post :generate_barcodes_range
  end

  member do
    get :barcode
    post :add_to_next_print
    delete :remove_from_next_print
  end
end
