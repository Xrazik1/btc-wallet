# frozen_string_literal: true

require 'spec_helper'
require 'uri'
require 'json'
require 'net/http'

RSpec.describe Api::MempoolSpace do
  let(:service) { described_class.new }
  let(:address) { 'mhkhVMBr2tz2U8AzVCauq9D61jt4pzKmw2' }
  let(:base_url) { described_class::BASE_URL }
  let(:utxo_uri) { URI("#{base_url}/address/#{address}/utxo") }
  let(:tx_uri) { URI("#{base_url}/tx") }
  let(:raw_tx_hex) { '01000000abcd1234' }

  describe '#fetch_utxos' do
    context 'when response is valid JSON' do
      let(:mock_body) { '[{"txid":"abc","vout":0,"value":12345}]' }

      before do
        allow(Net::HTTP).to receive(:get_response).with(utxo_uri).and_return(
          instance_double(Net::HTTPSuccess, body: mock_body)
        )
      end

      it 'returns parsed UTXOs with symbolized keys' do
        result = service.fetch_utxos(address)
        expect(result).to be_an(Array)
        expect(result.first[:txid]).to eq('abc')
      end
    end

    context 'when response is invalid JSON' do
      before do
        allow(Net::HTTP).to receive(:get_response).with(utxo_uri).and_return(
          instance_double(Net::HTTPResponse, body: 'not-json')
        )
      end

      it 'raises error on invalid JSON' do
        expect {
          service.fetch_utxos(address)
        }.to raise_error(RuntimeError, /Invalid JSON/)
      end
    end

    context 'when network request fails' do
      before { allow(Net::HTTP).to receive(:get_response).with(utxo_uri).and_raise(SocketError.new("network down")) }

      it 'raises error on network failure' do
        expect { service.fetch_utxos(address) }.to raise_error(RuntimeError, /Failed to fetch UTXOs/)
      end
    end
  end

  describe '#send_raw_transaction' do
    let(:mock_http) { instance_double(Net::HTTP) }

    context 'when broadcast is successful' do
      let(:mock_response) { instance_double(Net::HTTPSuccess, body: "abc123\n", is_a?: true) }

      before do
        allow(Net::HTTP).to receive(:start).with(tx_uri.host, tx_uri.port, use_ssl: true).and_yield(mock_http)
        allow(mock_http).to receive(:request).and_return(mock_response)
      end

      it 'returns txid from successful broadcast' do
        result = service.send_raw_transaction(raw_tx_hex)
        expect(result).to eq('abc123')
      end
    end

    context 'when broadcast fails' do
      let(:mock_response) { instance_double(Net::HTTPResponse, code: '400', body: 'error', is_a?: false) }

      before do
        allow(Net::HTTP).to receive(:start).with(tx_uri.host, tx_uri.port, use_ssl: true).and_yield(mock_http)
        allow(mock_http).to receive(:request).and_return(mock_response)
      end

      it 'raises error when broadcast fails' do
        expect { service.send_raw_transaction(raw_tx_hex) }.to raise_error(RuntimeError, /Broadcast failed: 400 error/)
      end
    end
  end
end
