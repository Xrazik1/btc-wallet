# frozen_string_literal: true

class NotEnoughBalanceError < RuntimeError
  def initialize(message = "Insufficient balance")
    super(message)
  end
end

class TransactionsAwaitingConfirmationsError < RuntimeError
  def initialize(message = "Some transactions awaiting confirmations")
    super(message)
  end
end
