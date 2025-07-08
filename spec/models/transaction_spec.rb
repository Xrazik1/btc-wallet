# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Models::Transaction do
  let(:recipient_address) { 'mhkhVMBr2tz2U8AzVCauq9D61jt4pzKmw2' }
  let(:wallet) { instance_double(Models::Wallet, address: 'sender_address') }
  let(:amount_btc) { 0.0005 }
  let(:amount_sats) { 50_000 }

  let(:utxos) do
    [
      { txid: 'abc123', vout: 0, value: 60_000, status: { confirmed: true }, address: 'sender_address' }
    ]
  end

  before do
    allow(Utils::Bitcoin).to receive(:btc_to_sats).with(amount_btc).and_return(amount_sats)
    allow_any_instance_of(Api::MempoolSpace).to receive(:fetch_utxos).and_return(utxos)
    allow(Bitcoin::Script).to receive(:parse_from_addr).and_call_original
  end

  describe '#send' do
    context 'when transaction is successful' do
      before do
        allow(Services::UtxoSelector).to receive(:new).and_return(double(call: { fee_sats: 192, selected_utxos: utxos }))
        allow(Services::TransactionSender).to receive(:new).and_return(double(call: 'tx123'))
      end

      it 'returns tx_id' do
        tx = described_class.new(recipient_address, amount_btc, wallet)
        result = tx.send

        expect(result).to eq({ success: true, tx_id: 'tx123' })
      end
    end

    context 'when balance is insufficient' do
      before { allow(Services::UtxoSelector).to receive(:new).and_raise(NotEnoughBalanceError) }

      it 'returns insufficient_funds error' do
        tx = described_class.new(recipient_address, amount_btc, wallet)
        result = tx.send

        expect(result).to eq({ success: false, error_code: 'insufficient_funds' })
      end
    end

    context 'when waiting for unconfirmed txs' do
      before { allow(Services::UtxoSelector).to receive(:new).and_raise(TransactionsAwaitingConfirmationsError) }

      it 'returns waiting_confirmations error' do
        tx = described_class.new(recipient_address, amount_btc, wallet)
        result = tx.send

        expect(result).to eq({ success: false, error_code: 'waiting_confirmations' })
      end
    end

    context 'when recipient address is invalid' do
      before do
        allow(Bitcoin::Script).to receive(:parse_from_addr).and_raise(StandardError)
        allow(Services::UtxoSelector).to receive(:new).and_return(double(call: { fee_sats: 192, selected_utxos: utxos }))
      end

      it 'returns invalid_recipient_address error' do
        tx = described_class.new("invalid_address", amount_btc, wallet)
        result = tx.send

        expect(result).to eq({ success: false, error_code: 'invalid_recipient_address' })
      end
    end

    context 'when amount is below dust limit' do
      before do
        allow(Utils::Bitcoin).to receive(:btc_to_sats).with(0.000001).and_return(100)
        allow(Services::UtxoSelector).to receive(:new).and_return(double(call: { fee_sats: 10, selected_utxos: utxos }))
      end

      it 'returns dust error' do
        tx = described_class.new(recipient_address, 0.000001, wallet)
        result = tx.send

        expect(result).to eq({ success: false, error_code: 'dust' })
      end
    end

    context 'when selected_utxos are empty' do
      before { allow(Services::UtxoSelector).to receive(:new).and_return(double(call: { fee_sats: 192, selected_utxos: [] })) }

      it 'returns utxos_empty error' do
        tx = described_class.new(recipient_address, amount_btc, wallet)
        result = tx.send

        expect(result).to eq({ success: false, error_code: 'utxos_empty' })
      end
    end

    context 'when any other error occurred' do
      before do
        allow_any_instance_of(Models::Transaction).to receive(:prepare).and_return(nil)
        allow(Services::TransactionSender).to receive(:new).and_raise(RuntimeError)
      end

      it 'returns unknown_error error' do
        tx = described_class.new(recipient_address, amount_btc, wallet)
        result = tx.send

        expect(result).to eq({ success: false, error_code: 'unknown_error' })
      end
    end
  end
end
