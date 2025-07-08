# frozen_string_literal: true

module Constants
  DUST_LIMIT_SATS = 546
  DUST_LIMIT_BTC = 0.00000546

  CLIENT_ERRORS = {
    invalid_recipient_address: "The recipient address is in incorrect format",
    dust: "The amount has to be greater than #{DUST_LIMIT_BTC} BTC",
    insufficient_funds: "Insufficient funds on the wallet balance",
    utxos_empty: "Insufficient funds on the wallet balance",
    waiting_confirmations: "Please wait for previous transactions to be confirmed",
    unknown_error: "An unexpected error occurred"
  }
end