Ixport::Engine.routes.draw do
  root "imports#index"
  resources :imports, only: %i[new create]
end
