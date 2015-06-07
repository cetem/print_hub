match 'catalog' => 'catalog#index', as: 'catalog', via: :get
match 'catalog/tags' => 'catalog#tags', via: :get
match 'catalog/:id' => 'catalog#show', as: 'show_catalog', via: :get
match 'catalog/:id/add_to_order' => 'catalog#add_to_order',
      as: 'add_to_order_catalog', via: :post
match 'catalog/:id/add_to_order_by_code' => 'catalog#add_to_order_by_code',
      as: 'add_to_order_by_code_catalog', via: :get
match 'catalog/:id/remove_from_order' => 'catalog#remove_from_order',
      as: 'remove_from_order_catalog', via: :delete
