# frozen_string_literal: true

class Product < ActiveRecord::Base
  belongs_to :account, optional: true

  validates :price_cents, numericality: true

  before_save { raise "Disk full" if sku == "RAISE" }
end
