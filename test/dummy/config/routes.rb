# frozen_string_literal: true

Rails.application.routes.draw do
  mount Ixport::Engine => "/data_imports"
  mount Wallflower::Engine => "/background"
end
