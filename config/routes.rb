PrintHubApp::Application.routes.draw do
  resources :articles

  resources :payments, :only => [:index]

  resources :customers

  resources :settings, :only => [:index, :show, :edit, :update]

  scope ':status', :defaults => {:status => 'all'},
    :constraints => {:status => /pending|scheduled|all/} do
    resources :prints, :except => [:destroy] do
      member do
        put :cancel_job
      end
      
      collection do
        get :autocomplete_for_customer_name
        get :autocomplete_for_document_name
        get :autocomplete_for_article_name
      end
    end
  end

  resources :documents do
    collection do
      get :autocomplete_for_tag_name
    end

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
    collection do
      delete :destroy
    end
  end

  resources :users, :except => [:destroy]

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'user_sessions#new'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
