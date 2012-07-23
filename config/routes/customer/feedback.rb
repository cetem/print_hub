match 'feedbacks/:item/:score' => 'feedbacks#create', as: 'new_feedback',
  via: :post, score: /positive|negative/
match 'feedbacks/:id' => 'feedbacks#update', as: 'update_feedback',
  via: :put
