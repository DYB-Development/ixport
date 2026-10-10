# frozen_string_literal: true

class BackOfficeController < ApplicationController
  before_action { response.set_header("X-Back-Office", "checked") }
end
