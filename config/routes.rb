PrintHubApp::Application.routes.draw do
  constraints(CustomerSubdomain) do
    match 'catalog' => 'catalog#index', as: 'catalog', via: :get
    match 'catalog/:id' => 'catalog#show', as: 'show_catalog', via: :get
    match 'catalog/:id/:style/download' => 'catalog#download',
      as: 'download_catalog', via: :get
    match 'catalog/:id/add_to_order' => 'catalog#add_to_order',
      as: 'add_to_order_catalog', via: :post
    match 'catalog/:id/add_to_order_by_code' => 'catalog#add_to_order_by_code',
      as: 'add_to_order_by_code_catalog', via: :get
    match 'catalog/:id/remove_from_order' => 'catalog#remove_from_order',
      as: 'remove_from_order_catalog', via: :delete
    
    match 'feedbacks/:item/:score' => 'feedbacks#create', as: 'new_feedback',
      via: :post, score: /positive|negative/
    match 'feedbacks/:id' => 'feedbacks#update', as: 'update_feedback',
      via: :put
    
    resources :customer_sessions, only: [:new, :create] do
      delete :destroy, on: :collection
    end
    
    match 'customers/activate/:token' => 'customers#activate',
      as: 'activate_customer', via: :get
    
    match 'password_resets/new' => 'password_resets#new',
      as: 'new_password_reset', via: :get
    match 'password_resets' => 'password_resets#create',
      as: 'password_resets', via: :post
    match 'password_resets/:token/edit' => 'password_resets#edit',
      as: 'edit_password_reset', via: :get
    match 'password_resets/:token' => 'password_resets#update',
      as: 'update_password_reset', via: :put
    
    resources :orders
    
    resources :customers, only: [:new, :create] do
      member do
        get :edit_profile
        put :update_profile
      end
    end
    
    root to: 'customer_sessions#new'
  end
  
  constraints(UserSubdomain) do
    match 'printer_stats(.:format)' => 'stats#printers',
      as: 'printer_stats', via: :get
    match 'user_stats(.:format)' => 'stats#users',
      as: 'user_stats', via: :get
    match 'print_stats(.:format)' => 'stats#prints',
      as: 'print_stats', via: :get

    resources :bonuses, only: [:index]

    resources :articles

    resources :payments, only: [:index]
    
    resources :shifts

    resources :customers do
      resources :prints, only: [:index]
      resources :bonuses, only: [:index]

      member do
        get :credit_detail
        put :pay_off_debt
        put :pay_month_debt
      end
    end

    resources :settings, only: [:index, :show, :edit, :update]
    
    resources :orders, only: [:index, :show, :destroy]

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

    resources :tags do
      resources :documents, only: [:index]
    end

    resources :user_sessions, only: [:new, :create] do
      delete :destroy, on: :collection
    end

    resources :users, except: [:destroy] do
      get :avatar, on: :member, path: '/avatar/:style'
      resources :shifts
    end

    root to: 'user_sessions#new'
  end
end