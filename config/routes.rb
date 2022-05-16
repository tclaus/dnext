# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  authenticate :user, lambda {|u| u.admin? } do
    # Important: Sidekiq is visible for all users!
  end

  # Defines the root path route ("/")
  root to: "home#show"
  get "podmin", to: "home#podmin"

  # Users and people
  controller :users do
    get "public/:username", action: :public, as: :users_public
    get "getting_started", action: :getting_started, as: :getting_started
  end

  resource :two_factor_authentication, only: %i[show create destroy] do
    get :confirm, action: :confirm_2fa
    post :confirm, action: :confirm_and_activate_2fa
    get :recovery_codes
  end

  devise_for :users, controllers: {sessions: :sessions}, skip: :registration

  devise_scope :user do
    get "/users/sign_up", to: "registrations#new", as: :new_user_registration
    post "/users", to: "registrations#create", as: :user_registration
    get "/registrations_closed", to: "registrations#registrations_closed", as: :registrations_closed
  end

  get "login" => redirect("/users/sign_in")

  resources :posts, only: %i[show destroy] do
    resources :likes, only: %i[create destroy]
    resources :comments, only: %i[new create destroy index]
    resources :reshares, only: :index
  end

  get "p/:id", to: "posts#show", as: "short_post"

  # Streams
  get "public", to: redirect("streams/public")
  get "stream", to: "streams#multi", as: :stream
  get "streams/public", to: "streams#public", as: :public_stream

  # Tags
  resources :tags, only: %i[index]
  get "tags/:name", to: "tags#show", as: "tag"

  resources "tag_followings", only: %i[create destroy index] do
    collection do
      get :manage
    end
  end

  # Interactions
  resource :likes, only: %i[create destroy]
  resources :reshares, only: %i[new create]

  # Users and people
  resources :people, only: %i[show index] do
    resources :photos, except: %i[new update]
  end
end
