scope ':status', defaults: { status: 'all' },
  constraints: { status: /pending|scheduled|pay_later|all/ } do
  resources :prints, except: [:destroy] do
    member do
      put :cancel_job
      delete :revoke
    end

    collection do
      get :autocomplete_for_customer_name
      get :autocomplete_for_document_name
      get :autocomplete_for_article_name
    end
  end
end
