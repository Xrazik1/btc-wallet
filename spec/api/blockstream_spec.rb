# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'net/http'

RSpec.describe Api::Blockstream do
  let(:service) { described_class.new }
  let(:txid) { '54702e5a43989da846bae50603f2ad5756b2a4e7dccabefe0ffe306fa1e3b26d' }
  let(:uri) { URI("https://blockstream.info/signet/api/tx/#{txid}") }

  describe '#fetch_tx' do
    context 'when the response is valid JSON' do
      let(:mock_response) do
        instance_double(
          Net::HTTPSuccess,
          body: '{"txid":"5470","vout":[]}',
          is_a?: true,
          code: '200'
        )
      end

      before { allow(Net::HTTP).to receive(:get_response).with(uri).and_return(mock_response) }

      it 'returns parsed transaction data' do
        result = service.fetch_tx(txid)

        expect(result).to be_a(Hash)
        expect(result[:txid]).to eq('5470')
      end
    end

    context 'when the response is invalid JSON' do
      let(:bad_response) do
        instance_double(
          Net::HTTPSuccess,
          body: 'not-json',
          is_a?: true,
          code: '200'
        )
      end

      before { allow(Net::HTTP).to receive(:get_response).with(uri).and_return(bad_response) }

      it 'raises error on invalid JSON' do
        expect { service.fetch_tx(txid) }.to raise_error(RuntimeError, /Invalid JSON response/)
      end
    end

    context 'when the HTTP request fails (network error)' do
      before { allow(Net::HTTP).to receive(:get_response).with(uri).and_raise(SocketError.new('network down')) }

      it 'raises error on network failure' do
        expect { service.fetch_tx(txid) }.to raise_error(SocketError, /network down/)
      end
    end

    context 'when the HTTP response is not successful' do
      let(:fail_response) do
        instance_double(
          Net::HTTPResponse,
          body: 'Not Found',
          is_a?: false,
          code: '404'
        )
      end

      before { allow(Net::HTTP).to receive(:get_response).with(uri).and_return(fail_response) }

      it 'raises an error when response code is not 2xx' do
        expect { service.fetch_tx(txid) }.to raise_error(RuntimeError, /HTTP error: 404/)
      end
    end
  end
end
