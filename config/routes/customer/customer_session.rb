# resources :customer_sessions, only: [:new, :create] do
#   delete :destroy, on: :collection
# end
devise_for :customers, path: 'customers', controllers: {
  sessions: 'customers/sessions' # poner todos los demas
}
