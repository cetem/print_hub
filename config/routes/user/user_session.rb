# resources :user_sessions, only: [:new, :create] do
#   delete :destroy, on: :collection
# end
devise_for :users, path: 'users', controllers: { sessions: 'users/sessions' }
