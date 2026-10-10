# frozen_string_literal: true

module Ixport
  class NullReporter
    def set_total(_total); end

    def advance; end

    def refuse(label:, reason:); end
  end
end
