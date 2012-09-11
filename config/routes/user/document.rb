resources :documents do
  get :autocomplete_for_tag_name, on: :collection

  member do
    get :barcode
    get :download_barcode
    post :add_to_next_print
    delete :remove_from_next_print

    scope ':style' do
      get :download
    end
  end
end
