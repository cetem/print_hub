scope ':status', defaults: { status: 'all' },
                 constraints: { status: /pending|scheduled|pay_later|all/ } do
  resources :prints, only: [:index, :show]
end
