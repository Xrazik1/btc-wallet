# frozen_string_literal: true

module Utils
  class Bitcoin
    class << self
      def sats_to_btc(sats)
        return 0 if sats.to_i.zero?
        sats.to_i / 100_000_000.0
      end

      def btc_to_sats(btc)
        (btc.to_f * 100_000_000).to_i
      end
    end
  end
end