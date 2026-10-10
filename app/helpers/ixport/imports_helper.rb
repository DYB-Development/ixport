# frozen_string_literal: true

module Ixport
  module ImportsHelper
    def import_step_path(import)
      case import.step
      when :result then import_path(import)
      when :preview then import_preview_path(import)
      else import_mapping_path(import)
      end
    end
  end
end
