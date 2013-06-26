scope ':status', defaults: { status: 'all' },
  constraints: { status: /pending|scheduled|pay_later|all/ } do
  resources :prints, except: [:destroy] do
    member do
      patch :cancel_job
      delete :revoke
      get :related_by_customer
    end

    collection do
      get :autocomplete_for_customer_name
      get :autocomplete_for_document_name
      get :autocomplete_for_article_name
    end
  end
end
