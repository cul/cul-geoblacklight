Rails.application.routes.draw do

  # devise_for :users

  devise_for :users, controllers: { sessions: 'users/sessions', :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end

  # admin page
  get 'admin/system'

  concern :gbl_exportable, Geoblacklight::Routes::Exportable.new
  resources :solr_documents, only: [:show], controller: 'catalog' do
    concerns :gbl_exportable
  end

  concern :gbl_wms, Geoblacklight::Routes::Wms.new
  namespace :wms do
    concerns :gbl_wms
  end

  concern :gbl_downloadable, Geoblacklight::Routes::Downloadable.new
  namespace :download do
    concerns :gbl_downloadable
  end

  resources :download, only: [:show]

  mount Geoblacklight::Engine => 'geoblacklight'
  mount Blacklight::Engine => '/'

  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

end
