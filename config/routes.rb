Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root  'covid19_monitor#home'
  get '/select_area/:id', to: 'covid19_monitor#home', as: 'select_area'
end
