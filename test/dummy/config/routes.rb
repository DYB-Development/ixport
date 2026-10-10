# frozen_string_literal: true

Rails.application.routes.draw do
  mount Ixport::Engine => "/data_imports"
end
