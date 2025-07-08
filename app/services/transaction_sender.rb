# frozen_string_literal: true

require 'bitcoin'
require 'net/http'
require 'uri'
require 'json'

Bitcoin.chain_params = :signet

module Services
  class TransactionSender
    def initialize(params)
      @recipient_address = params[:recipient_address]
      @amount_sats       = params[:amount_sats]
      @fee_sats          = params[:fee_sats]
      @inputs            = params[:inputs]
      @private_key_hex   = Models::PrivateKey.new.get
    end

    def call
      broadcast
    end

    private

    attr_reader :recipient_address, :amount_sats, :fee_sats, :inputs, :private_key_hex

    def broadcast
      key = Bitcoin::Key.new(priv_key: private_key_hex, key_type: Bitcoin::Key::TYPES[:p2pkh])
      expected_address = key.to_addr
      utxo_address = inputs.first[:address]

      raise RuntimeError, "Private key doesn't match UTXO address" unless expected_address == utxo_address

      tx = build_transaction(key)
      mempool_api.send_raw_transaction(tx.to_hex)
    end

    def build_transaction(key)
      tx = Bitcoin::Tx.new
      total_input_value = 0

      inputs.each do |utxo|
        total_input_value += utxo[:value]
        outpoint = Bitcoin::OutPoint.new(utxo[:txid].htb.reverse.bth, utxo[:vout])

        txin = Bitcoin::TxIn.new(
          out_point: outpoint,
          script_sig: Bitcoin::Script.new,
          sequence: Bitcoin::TxIn::SEQUENCE_FINAL
        )

        tx.inputs << txin
      end

      change = total_input_value - amount_sats - fee_sats
      raise NotEnoughBalanceError, "Insufficient funds" if change < 0

      recipient_script = Bitcoin::Script.parse_from_addr(recipient_address)
      tx.outputs << Bitcoin::TxOut.new(value: amount_sats, script_pubkey: recipient_script)

      if change > 0
        change_script = Bitcoin::Script.parse_from_addr(key.to_addr)
        tx.outputs << Bitcoin::TxOut.new(value: change, script_pubkey: change_script)
      end

      inputs.each_with_index do |utxo, index|
        utxo_script = Bitcoin::Script.parse_from_addr(utxo[:address])
        sighash = tx.sighash_for_input(index, utxo_script)
        sig = key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')

        script_sig = Bitcoin::Script.new
        script_sig << sig
        script_sig << [key.pubkey].pack('H*')
        tx.inputs[index].script_sig = script_sig
      end

      tx
    end

    def mempool_api
      @mempool_api ||= Api::MempoolSpace.new
    end
  end
end
