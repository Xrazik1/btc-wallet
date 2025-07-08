# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Services::CatchTransactions do
  let(:address) { 'mhkhVMBr2tz2U8AzVCauq9D61jt4pzKmw2' }
  let(:seen_file) { described_class::SEEN_FILE }

  let(:valid_utxo) { { txid: 'tx1', vout: 0, value: 100_000, status: { confirmed: false } } }
  let(:new_utxo)   { { txid: 'tx2', vout: 1, value: 200_000, status: { confirmed: false } } }

  let(:fetched_utxos_initial) { [valid_utxo] }
  let(:fetched_utxos_updated) { [valid_utxo, new_utxo] }

  let(:tx_response_valid) do
    {
      txid: valid_utxo[:txid],
      vout: [
        { scriptpubkey_address: address }
      ]
    }
  end

  let(:tx_response_new) do
    {
      txid: new_utxo[:txid],
      vout: [
        {}, # vout[0]
        { scriptpubkey_address: address } # vout[1]
      ]
    }
  end

  before do
    allow_any_instance_of(described_class).to receive(:sleep)

    allow(FileUtils).to receive(:mkdir_p)
    allow(Dir).to receive(:exist?).with('tmp').and_return(true)

    allow(File).to receive(:exist?).with(seen_file).and_return(false)
    allow(File).to receive(:write)
    allow(File).to receive(:read)

    allow_any_instance_of(Models::Address).to receive(:get).and_return(address)
    allow_any_instance_of(Api::MempoolSpace).to receive(:fetch_utxos).and_return(fetched_utxos_initial)

    allow_any_instance_of(Api::Blockstream).to receive(:fetch_tx).with('tx1').and_return(tx_response_valid)
    allow_any_instance_of(Api::Blockstream).to receive(:fetch_tx).with('tx2').and_return(tx_response_new)

    allow(Utils::Bitcoin).to receive(:sats_to_btc).and_return(0.001)
  end

  describe '#initialize' do
    it 'writes valid initial UTXOs to the seen file' do
      expect(File).to receive(:write).with(
        seen_file,
        JSON.pretty_generate([{ txid: 'tx1', vout: 0, value: 100_000 }])
      )

      described_class.new
    end
  end

  describe '#call' do
    subject(:service) do
      described_class.allocate.tap do |instance|
        allow(instance).to receive(:prepare)
        instance.send(:initialize)
      end
    end

    before do
      allow(File).to receive(:exist?).with(seen_file).and_return(true)
      allow(File).to receive(:read).with(seen_file).and_return(
        JSON.pretty_generate([{ txid: 'tx1', vout: 0, value: 100_000 }])
      )
    end

    context 'when a new valid UTXO appears' do
      before { allow_any_instance_of(Api::MempoolSpace).to receive(:fetch_utxos).and_return(fetched_utxos_updated) }

      it 'saves and prints the new UTXO' do
        expect(File).to receive(:write).with(
          seen_file,
          JSON.pretty_generate(
            [
              { txid: 'tx1', vout: 0, value: 100_000 },
              { txid: 'tx2', vout: 1, value: 200_000 }
            ])
        )

        expect(service).to receive(:print_fulfilments).with([{ txid: 'tx2', vout: 1, value: 200_000 }])
        service.call
      end
    end

    context 'when there are no new UTXOs' do
      it 'does not print or write anything' do
        expect(File).not_to receive(:write)
        expect(service).not_to receive(:print_fulfilments)

        service.call
      end
    end

    context 'when the new UTXO does not match the address' do
      before do
        allow_any_instance_of(Api::MempoolSpace).to receive(:fetch_utxos).and_return([new_utxo])
        allow_any_instance_of(Api::Blockstream).to receive(:fetch_tx).with('tx2').and_return(
          {
            txid: 'tx2',
            vout: [
              {}, {}, { scriptpubkey_address: 'some-other-address' }
            ]
          }
        )
      end

      it 'ignores unmatched utxos' do
        expect(File).not_to receive(:write)
        expect(service).not_to receive(:print_fulfilments)

        service.call
      end
    end
  end

  describe '#save_known_utxos' do
    subject(:service) do
      described_class.allocate.tap do |instance|
        allow(instance).to receive(:prepare)
        instance.send(:initialize)
      end
    end

    before do
      allow(File).to receive(:exist?).with(seen_file).and_return(true)
      allow(File).to receive(:read).with(seen_file).and_return(
        JSON.pretty_generate([{ txid: 'tx1', vout: 0, value: 100_000 }])
      )
    end

    it 'saves additional UTXOs without duplicating existing ones' do
      expect(File).to receive(:write).with(
        seen_file,
        JSON.pretty_generate(
          [
            { txid: 'tx1', vout: 0, value: 100_000 },
            { txid: 'tx2', vout: 1, value: 200_000 }
          ])
      )

      service.send(:save_known_utxos, [
        { txid: 'tx1', vout: 0, value: 100_000 },
        { txid: 'tx2', vout: 1, value: 200_000 }
      ])
    end
  end
end
