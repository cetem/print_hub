PrintHubApp::Application.routes.draw do
  constraints :subdomain => /\Afotocopia/i do
    resources :customer_sessions, :only => [:new, :create] do
      delete :destroy, :on => :collection
    end
    
    resources :orders
    
    root :to => 'customer_sessions#new'
  end
  
  constraints :subdomain => '' do
    match 'printer_stats(.:format)' => 'stats#printers', :as => 'printer_stats',
      :via => :get
    match 'user_stats(.:format)' => 'stats#users', :as => 'user_stats',
      :via => :get

    resources :orders, :only => [:index]

    resources :bonuses, :only => [:index]

    resources :articles

    resources :payments, :only => [:index]

    resources :customers do
      resources :prints, :only => [:index]
      resources :bonuses, :only => [:index]

      get :credit_detail, :on => :member
    end

    resources :settings, :only => [:index, :show, :edit, :update]

    scope ':status', :defaults => {:status => 'all'},
      :constraints => {:status => /pending|scheduled|all/} do
      resources :prints, :except => [:destroy] do
        put :cancel_job, :on => :member

        collection do
          get :autocomplete_for_customer_name
          get :autocomplete_for_document_name
          get :autocomplete_for_article_name
        end
      end
    end

    resources :documents do
      get :autocomplete_for_tag_name, :on => :collection

      member do
        post :add_to_next_print
        delete :remove_from_next_print

        scope ':style' do
          get :download
        end
      end
    end

    resources :tags do
      resources :documents, :only => [:index]
    end

    resources :user_sessions, :only => [:new, :create] do
      delete :destroy, :on => :collection
    end

    resources :users, :except => [:destroy] do
      get :avatar, :on => :member, :path => '/avatar/:style'
    end
  
    root :to => 'user_sessions#new'
  end
end