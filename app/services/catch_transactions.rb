# frozen_string_literal: true

require 'net/http'
require 'json'

module Services
  class CatchTransactions
    REQUEST_DELAY = 3

    SEEN_FILE = 'tmp/known-utxos.json'

    def initialize
      @address = Models::Address.new.get
      prepare
    end

    def call
      fetched_utxos = mempool_api.fetch_utxos(address)
      fetched_utxos = fetched_utxos.reject { |utxo| utxo[:status][:confirmed] }
      new_utxos = filter_and_detect_new_utxos(fetched_utxos)

      if new_utxos.any?
        save_known_utxos(new_utxos)
        print_fulfilments(new_utxos)
      end
    end

    private

    attr_reader :address

    def prepare
      Dir.mkdir('tmp') unless Dir.exist?('tmp')
      initial_utxos = mempool_api.fetch_utxos(address)
      valid = validate_utxos_by_address(initial_utxos)
      save_known_utxos(valid)
    end

    def filter_and_detect_new_utxos(utxos)
      known = load_known_utxos
      known_keys = known.map { |u| [u[:txid], u[:vout]] }
      valid = validate_utxos_by_address(utxos)

      valid.reject { |u| known_keys.include?([u[:txid], u[:vout]]) }
    end

    def validate_utxos_by_address(utxos)
      selected = utxos.select { |utxo| tx_vout_matches_address?(utxo[:txid], utxo[:vout]) }
      selected.map { |u| { txid: u[:txid], vout: u[:vout], value: u[:value] } }
    end

    def tx_vout_matches_address?(txid, vout_index)
      sleep REQUEST_DELAY
      tx = blockstream_api.fetch_tx(txid)

      return false unless tx

      vout = tx[:vout][vout_index]

      return false unless vout

      vout[:scriptpubkey_address] == address
    rescue
      false
    end

    def print_fulfilments(utxos)
      utxos.each do |utxo|
        puts "🔔 New fulfilment detected [#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}]"
        puts "────────────────────────────"
        puts "txId:   #{utxo[:txid]}"
        puts "amount: #{Utils::Bitcoin.sats_to_btc(utxo[:value])} BTC"
        puts "────────────────────────────"
      end
    end

    def load_known_utxos
      return [] unless File.exist?(SEEN_FILE)
      JSON.parse(File.read(SEEN_FILE), symbolize_names: true)
    end

    def save_known_utxos(utxos)
      existing = load_known_utxos
      existing_keys = existing.map { |u| [u[:txid], u[:vout]] }

      new_entries = utxos.reject { |u| existing_keys.include?([u[:txid], u[:vout]]) }
      combined = existing + new_entries

      File.write(SEEN_FILE, JSON.pretty_generate(combined))
    end

    def blockstream_api
      @blockstream_api ||= Api::Blockstream.new
    end

    def mempool_api
      @mempool_api ||= Api::MempoolSpace.new
    end
  end
end
