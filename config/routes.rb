Rails.application.routes.draw do
  # Defines the root path route ("/")
  root 'home#show'

  get 'streams/public'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html


end
