Rails.application.routes.draw do
  # Defines the root path route ("/")
  root to: "home#show"

  # Users and people
  controller :users do
    get "public/:username", action: :public, as: :users_public
    get "getting_started", action: :getting_started, as: :getting_started
  end

  devise_for :users, controllers: {sessions: :sessions}, skip: :registration

  devise_scope :user do
    get "/users/sign_up", to: "registrations#new", as: :new_user_registration
    post "/users", to: "registrations#create", as: :user_registration
    get "/registrations_closed", to: "registrations#registrations_closed", as: :registrations_closed
  end

  get "login" => redirect("/users/sign_in")

  # Streams
  get "public", to: redirect("streams/public")
  get "streams/public", to: "streams#public", as: :public_stream
end
