# frozen_string_literal: true

require_relative '../initialize'

unless STDIN.tty?
  puts "❌ This CLI must be run in interactive mode."
  puts "✅ Try: docker compose run --rm client"
  exit 1
end

def print_main_panel(wallet)
  balance_prepend = wallet.unconfirmed_balance&.fetch(:btc, nil)&.positive? ? " (unconfirmed #{wallet.unconfirmed_balance[:btc]} BTC)" : ""
  balance = wallet.confirmed_balance&.fetch(:btc, nil)&.positive? ? wallet.confirmed_balance[:btc] : 0

  puts "\n📦 Bitcoin Wallet"
  puts "────────────────────────────"
  puts "📬 Address:  #{wallet.address}"
  puts "💰 Balance:  #{balance} BTC#{balance_prepend}"
  puts "────────────────────────────"
end

wallet = Models::Wallet.new
wallet.balance!
print_main_panel(wallet)

loop do
  puts "\nChoose action:"
  puts "1. Send BTC"
  puts "2. Refresh balance"
  puts "3. Exit"

  print "> "
  input = STDIN.gets
  break if input.nil?

  choice = input.strip

  case choice
  when "1"
    print "\nEnter recipient address: "
    to_address = STDIN.gets&.strip

    print "Enter amount in BTC: "
    amount_input = STDIN.gets
    break if amount_input.nil?
    amount = amount_input.strip.to_f

    puts "\n🔄 Sending transaction..."

    tx = Models::Transaction.new(to_address, amount, wallet)
    result = tx.send

    if result[:success]
      puts "\n✅ Transaction sent. TxId: #{result[:tx_id]}"
    else
      puts "\n❌ Sending error: '#{Constants::CLIENT_ERRORS[result[:error_code].to_sym]}'"
    end

  when "2"
    wallet.balance!
    print_main_panel(wallet)

  when "3"
    puts "\n👋 See you later!"
    break

  else
    puts "\n⚠️ Invalid option. Please try again"
  end
end

