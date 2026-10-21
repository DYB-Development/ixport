# frozen_string_literal: true

Rails.application.routes.draw do
  get "/quizzes", to: ->(_env) { [ 200, {}, [ "Quizzes" ] ] }, as: :quizzes
  mount Ixport::Engine => "/data_imports"
  mount Wallflower::Engine => "/background"
end
