# frozen_string_literal: true

require_relative '../initialize'

catch_transaction = Services::CatchTransactions.new

puts "Listening for new transactions..."

loop do
  begin
    catch_transaction.call
  rescue => e
    warn "⚠️ An error occurred while fetching new transactions: #{e.message}"
  end

  sleep 10
end
