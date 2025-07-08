module Services
  class UtxoSelector
    attr_reader :wallet, :amount_sats, :utxos

    OUTPUTS_COUNT   = 2    # recipient + change
    FEE_RATE_SATS   = 1
    INPUT_SIZE      = 148  # P2PKH
    OUTPUT_SIZE     = 34   # P2PKH
    BASE_SIZE       = 10
    MEMPOOL_MIN_FEE = 546

    def initialize(amount_sats, utxos, wallet)
      @amount_sats = amount_sats
      @wallet = wallet
      @utxos = utxos.sort_by { |utxo| -utxo[:value].to_i }
    end

    def call
      return @selected_utxos_with_fee if instance_variable_defined?(:@selected_utxos_with_fee)

      confirmed = utxos.select { |u| u[:status][:confirmed] }
      all       = utxos

      selection = select_enough(confirmed)
      return selection if selection

      selection_all = select_enough(all)

      raise NotEnoughBalanceError, "Insufficient funds to cover amount + fee" unless selection_all
      raise TransactionsAwaitingConfirmationsError, "Enough funds, but waiting for confirmations"
    end

    private

    def select_enough(utxos_list)
      selected = []
      total = 0

      utxos_list.each do |utxo|
        selected << utxo
        total += utxo[:value]
        fee = estimate_fee(selected.count)

        if total >= amount_sats + fee
          selected.each { |u| u[:address] = wallet.address }
          @selected_utxos_with_fee = { selected_utxos: selected, fee_sats: fee }
          return @selected_utxos_with_fee
        end
      end

      nil
    end

    def estimate_fee(inputs_count)
      size = inputs_count * INPUT_SIZE + OUTPUTS_COUNT * OUTPUT_SIZE + BASE_SIZE
      fee = (size * FEE_RATE_SATS).ceil
      return MEMPOOL_MIN_FEE if fee < MEMPOOL_MIN_FEE

      fee
    end
  end
end
