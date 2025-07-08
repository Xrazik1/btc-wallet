# frozen_string_literal: true

require "bitcoin"

module Models
  class Transaction
    attr_reader :recipient_address, :wallet, :amount_btc, :fee_sats, :selected_utxos

    def initialize(recipient_address, amount_btc, wallet)
      @recipient_address = recipient_address
      @amount_btc = amount_btc
      @wallet = wallet
    end

    def send
      preparation_result = prepare
      return preparation_result unless preparation_result[:success]

      params = { recipient_address: recipient_address, amount_sats: amount_sats, fee_sats: fee_sats, inputs: selected_utxos }

      tx_id = Services::TransactionSender.new(params).call
      { success: true, tx_id: tx_id }
    rescue NotEnoughBalanceError
      return { success: false, error_code: "insufficient_funds" }
    rescue TransactionsAwaitingConfirmationsError
      return { success: false, error_code: "waiting_confirmations" }
    rescue
      return { success: false, error_code: "unknown_error" }
    end

    private

    def prepare
      selected_utxos_with_fee = Services::UtxoSelector.new(amount_sats, utxos, wallet).call

      @fee_sats = selected_utxos_with_fee[:fee_sats]
      @selected_utxos = selected_utxos_with_fee[:selected_utxos]

      validate
    end

    def validate
      return { success: false, error_code: "invalid_recipient_address" } unless recipient_address_valid?
      return { success: false, error_code: "dust" } if amount_sats <= Constants::DUST_LIMIT_SATS
      return { success: false, error_code: "utxos_empty" } unless selected_utxos&.any?

      { success: true }
    end

    def utxos
      return @utxos if instance_variable_defined?(:@utxos)
      @utxos = mempool_api.fetch_utxos(wallet.address)
    end

    def recipient_address_valid?
      script = Bitcoin::Script.parse_from_addr(recipient_address)
      script.standard?
    rescue StandardError
      false
    end

    def mempool_api
      return @mempool_api if instance_variable_defined?(:@utxos)
      @mempool_api = Api::MempoolSpace.new
    end

    def amount_sats
      return @amount_sats if instance_variable_defined?(:@amount_sats)
      @amount_sats = Utils::Bitcoin.btc_to_sats(amount_btc)
    end
  end
end