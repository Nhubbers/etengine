Etm::Application.routes.draw do  
  root :to => 'pages#index'
  
  match 'login'  => 'user_sessions#new',     :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :user_sessions
  
  # Frontend
  resources :converters, :only => [:show]
  resource :graph, :only => :show

  scope '/api/v2', :module => 'api' do
    resources :scenarios, :only => [:index, :show, :create, :update] do
      get :load, :on => :member
      collection do
        get :homepage
      end
    end    
    resources :api_scenarios do
      member do 
        get :user_values
        get :input_data
      end
    end
    resources :areas, :only => [:index, :show]
    resources :inputs, :only => [:index, :show]
    resources :gqueries, :only => [:index]
    # catches all OPTIONS requests
    match '*url', to: 'base#cross_site_sharing', via: :options
  end

  namespace :data do
    root :to => "pages#index", :api_scenario_id => 'latest'
    
    match '/redirect'    => "base#redirect", :as => 'redirect'
    match '/restart'     => 'pages#restart', :as => 'restart'
    match '/clear_cache' => 'pages#clear_cache', :as => 'clear_cache'

    scope '/:api_scenario_id' do
      scope "/nl" do
        match "*path" => "pages#url_changed"
      end

      root :to => "pages#index"
      resources :blueprint_layouts, :except => [:update, :destroy] do
        resources :converter_positions, :only => :create
      end
      
      scope "/etsource" do
        resources :commits, :only => [:index, :show] do
          get :import, :on => :member
        end
      end

      resources :gqueries do
        get :result, :on => :member
        collection do
          get :dump
          post :dump
          get :test
          post :test
          get :result
          get :group_descriptions
        end
      end
      match "/gqueries/key/:key" => "gqueries#key", :as => :gquery_key

      resources :fce_values

      resources :converters, :only => [:index, :edit, :show] 
      resources :gquery_groups, :only => [:index, :show]
      resources :carriers, :only => [:index, :show]
      resource  :area, :as => :area

      resources :gql_test_cases
      resources :query_tables
      resources :query_table_cells, :except => [:show, :index]
      resources :inputs, :except => :show

      resources :scenarios, :only => [:index, :show, :edit, :update, :new] do
        put :fix, :on => :member
      end
      resources :energy_balance_groups

      match '/gql' => "gql#index"
      match '/gql/search' => "gql#search", :as => :gql_search
      match '/gql/log' => "gql#log", :as => :gql_log
    end
  end

  namespace :input_tool do
    root :to => "wizards#index"
    resources :wizards
  end
end
