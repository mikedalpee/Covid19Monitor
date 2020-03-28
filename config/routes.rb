Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root  'covid19_monitor#home'
  get '/select_area/:id', to: 'covid19_monitor#select_area', as: 'select_area'
  get '/unselect_area/:id', to: 'covid19_monitor#unselect_area', as: 'unselect_area'
  get '/set_interval/:interval', to: 'covid19_monitor#set_interval', as: 'set_interval'
  get '/set_query/:query_id', to: 'covid19_monitor#set_query', as: 'set_query'
end
