# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::TransactionSender do
  let(:recipient_address) { 'mhkhVMBr2tz2U8AzVCauq9D61jt4pzKmw2' }
  let(:private_key_hex)   { '4f3edf983ac63e6c9eab9d9250b37c99d2d29a2586e93c1bc980f843865a4d13' }

  let(:sender_key)        { Bitcoin::Key.new(priv_key: private_key_hex, key_type: Bitcoin::Key::TYPES[:p2pkh]) }
  let(:sender_address)    { sender_key.to_addr }

  let(:utxos) do
    [
      {
        txid: '72ac3294a64ebb1a3a6c9978eb3c1bd8b8297a5e64130434035ce7137f22f01c',
        vout: 0,
        value: 100_000,
        address: sender_address
      }
    ]
  end

  let(:params) do
    {
      recipient_address: recipient_address,
      amount_sats: 50_000,
      fee_sats: 192,
      inputs: utxos
    }
  end

  before do
    allow(Models::PrivateKey).to receive_message_chain(:new, :get).and_return(private_key_hex)
    allow(Bitcoin::Script).to receive(:parse_from_addr).and_call_original
    allow_any_instance_of(Bitcoin::Tx).to receive(:sighash_for_input).and_return("sighash")
  end

  describe '#call' do
    let(:fake_txid) { 'fake-tx-id-123' }
    let(:mock_api) { double("MempoolSpace", send_raw_transaction: fake_txid) }

    before { allow(Api::MempoolSpace).to receive(:new).and_return(mock_api) }

    it 'builds and sends transaction, returns txid' do
      sender = described_class.new(params)
      result = sender.call

      expect(result).to eq(fake_txid)
    end

    it 'raises if private key address does not match UTXO address' do
      wrong_utxo = utxos.map { |u| u.merge(address: 'mwrong1234567890wrong') }
      invalid_params = params.merge(inputs: wrong_utxo)

      sender = described_class.new(invalid_params)

      expect {
        sender.call
      }.to raise_error(RuntimeError, /Private key doesn't match UTXO address/)
    end

    it 'raises NotEnoughBalanceError if change is negative' do
      invalid_params = params.merge(amount_sats: 99_000, fee_sats: 2_000)
      sender = described_class.new(invalid_params)

      expect { sender.call }.to raise_error(NotEnoughBalanceError)
    end
  end
end
