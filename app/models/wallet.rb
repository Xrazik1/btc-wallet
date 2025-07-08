# frozen_string_literal: true

module Models
  class Wallet
    attr_reader :address, :confirmed_balance, :unconfirmed_balance, :total_balance

    def initialize
      @address = Address.new.get
    end

    def balance!
      utxos = Api::MempoolSpace.new.fetch_utxos(address)

      confirmed_balance_sats = 0
      unconfirmed_balance_sats = 0
      total_balance_sats = 0

      utxos.each do |utxo|
        confirmed_balance_sats += utxo[:value] if utxo[:status][:confirmed]
        unconfirmed_balance_sats += utxo[:value] unless utxo[:status][:confirmed]
        total_balance_sats = confirmed_balance_sats + unconfirmed_balance_sats
      end

      @confirmed_balance = { sats: confirmed_balance_sats, btc: Utils::Bitcoin.sats_to_btc(confirmed_balance_sats) }
      @unconfirmed_balance = { sats: unconfirmed_balance_sats, btc: Utils::Bitcoin.sats_to_btc(unconfirmed_balance_sats) }
      @total_balance = { sats: total_balance_sats, btc: Utils::Bitcoin.sats_to_btc(total_balance_sats) }
    end
  end
end
