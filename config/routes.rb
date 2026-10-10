Ixport::Engine.routes.draw do
  root "imports#index"
  resources :imports, only: %i[new create] do
    resource :mapping, only: :show
  end
end
