resource :report, only: [], controller: :reports do
  get :printed_documents
  get :sold_articles
end

