Ixport::Engine.routes.draw do
  root "imports#index"
  resources :exports, only: %i[index show] do
    resources :templates, only: :create, controller: "export_templates"
  end
  resources :imports, only: %i[new create show] do
    resource :mapping, only: %i[show update]
    resource :preview, only: :show
    resource :run, only: :create
  end
end
