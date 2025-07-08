# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Services::UtxoSelector do
  let(:wallet) { double('Wallet', address: 'mhkhVMBr2tz2U8AzVCauq9D61jt4pzKmw2') }
  let!(:service) { described_class.new(amount_sats, utxos, wallet) }
  let(:minimum_fee) { Services::UtxoSelector::MEMPOOL_MIN_FEE }

  let(:amount_sats) { 50_000 }
  let(:fee_for_4_inputs) do
    # 4 inputs, 2 outputs, base size
    size = 4 * 148 + 2 * 34 + 10
    size * 1
  end

  let(:fee_for_1_input) do
    # 1 input, 2 outputs, base size
    size = 3 * 148 + 2 * 34 + 10
    size * 1
  end

  describe '#call' do
    context 'when confirmed utxos are enough' do
      context "when calculated is more than minimum fee" do
        let(:amount_sats) { 168_000 }

        let(:utxos) do
          [
            { txid: 'abc1', vout: 0, value: 100_000, status: { confirmed: true } },
            { txid: 'abc2', vout: 1, value: 20_000, status: { confirmed: true } },
            { txid: 'abc3', vout: 2, value: 40_000, status: { confirmed: true } },
            { txid: 'abc4', vout: 3, value: 10_000, status: { confirmed: true } }
          ]
        end

        it 'returns selected utxos and fee' do
          result = service.call

          expect(result[:selected_utxos]).to all(include(:txid, :value, :status, :address))
          expect(result[:fee_sats]).to eq(fee_for_4_inputs)
          expect(result[:selected_utxos].map { |u| u[:address] }.uniq).to eq([wallet.address])
        end
      end

      context "when calculated is less than minimum fee" do
        let(:utxos) do
          [
            { txid: 'abc1', vout: 0, value: 100_000, status: { confirmed: true } },
            { txid: 'abc2', vout: 1, value: 20_000, status: { confirmed: true } }
          ]
        end

        it 'returns minimal fee if calculated is not enough' do
          result = service.call

          expect(result[:selected_utxos]).to all(include(:txid, :value, :status, :address))
          expect(result[:fee_sats]).to eq(minimum_fee)
          expect(result[:selected_utxos].map { |u| u[:address] }.uniq).to eq([wallet.address])
        end
      end
    end

    context 'when confirmed are not enough but total is enough with unconfirmed' do
      let(:utxos) do
        [
          { txid: 'abc3', vout: 0, value: 20_000, status: { confirmed: true } },
          { txid: 'abc4', vout: 1, value: 40_000, status: { confirmed: false } }
        ]
      end

      it 'raises TransactionsAwaitingConfirmationsError' do
        expect { service.call }.to raise_error(TransactionsAwaitingConfirmationsError, /waiting for confirmations/)
      end
    end

    context 'when utxos are not enough even with unconfirmed' do
      let(:utxos) do
        [
          { txid: 'abc5', vout: 0, value: 10_000, status: { confirmed: false } }
        ]
      end

      it 'raises NotEnoughBalanceError' do
        expect { service.call }.to raise_error(NotEnoughBalanceError, /Insufficient funds/)
      end
    end

    context 'memoization works on second call' do
      let(:utxos) do
        [
          { txid: 'abc6', vout: 0, value: 100_000, status: { confirmed: true } }
        ]
      end

      it 'returns cached result' do
        first = service.call
        expect(service.call).to equal(first)
      end
    end
  end
end
