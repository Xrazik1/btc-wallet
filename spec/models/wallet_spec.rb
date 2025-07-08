# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Models::Wallet do
  let(:address_value) { 'mhkhVMBr2tz2U8AzVCauq9D61jt4pzKmw2' }
  let(:wallet) { described_class.new }

  before { allow_any_instance_of(Models::Address).to receive(:get).and_return(address_value) }

  describe '#initialize' do
    it 'assigns address from Models::Address' do
      expect(wallet.address).to eq(address_value)
    end
  end

  describe '#balance!' do
    let(:mocked_utxos) do
      [
        { value: 100_000, status: { confirmed: true } },
        { value: 50_000,  status: { confirmed: false } },
        { value: 75_000,  status: { confirmed: true } }
      ]
    end

    before do
      allow_any_instance_of(Api::MempoolSpace).to receive(:fetch_utxos).with(address_value).and_return(mocked_utxos)
      allow(Utils::Bitcoin).to receive(:sats_to_btc) { |sats| (sats / 100_000_000.0).round(8) }
    end

    it 'calculates confirmed, unconfirmed, and total balances correctly' do
      wallet.balance!

      expect(wallet.confirmed_balance).to eq({ sats: 175_000, btc: 0.00175 })
      expect(wallet.unconfirmed_balance).to eq({ sats: 50_000, btc: 0.0005 })
      expect(wallet.total_balance).to eq({ sats: 225_000, btc: 0.00225 })
    end
  end
end
