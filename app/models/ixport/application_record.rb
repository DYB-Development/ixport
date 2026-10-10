# frozen_string_literal: true

module Ixport
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
