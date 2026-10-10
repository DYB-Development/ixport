Ixport::Engine.routes.draw do
  root "imports#index"
  resources :imports, only: :create
end
