# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Models::Address do
  let(:address_path) { Models::Address::ADDRESS_PATH }
  let(:address) { described_class.new }

  before do
    @original_address = File.read(address_path).strip if File.exist?(address_path)
    File.delete(address_path) if File.exist?(address_path)
  end

  after do
    if @original_address
      File.write(address_path, @original_address)
    elsif File.exist?(address_path)
      File.delete(address_path)
    end
  end

  describe '#get' do
    context 'when address file exists' do
      before { File.write(address_path, "mhkhVMBr2tz2U8AzVCauq9D61jt4pzKmw2") }

      it 'reads address from file' do
        expect(address.get).to eq("mhkhVMBr2tz2U8AzVCauq9D61jt4pzKmw2")
      end
    end

    context 'when address file does not exist' do
      it 'generates and saves new address' do
        generated_address = address.get

        expect(generated_address).to be_a(String)
        expect(generated_address).to match(/\A[mn2][1-9A-HJ-NP-Za-km-z]{25,34}\z/)
        expect(File.exist?(address_path)).to be true
        expect(File.read(address_path).strip).to eq(generated_address)
      end
    end

    context 'when private key is invalid' do
      before { allow_any_instance_of(Models::PrivateKey).to receive(:get).and_return('00' * 32) }

      it 'raises an error if private key is zero or exceeds group order' do
        expect { address.get }.to raise_error(RuntimeError, /Invalid private key/)
      end
    end

    context 'when pubkey hash is invalid length' do
      before do
        allow_any_instance_of(Models::PrivateKey).to receive(:get).and_return(('01' * 32))
        allow(address).to receive(:hash160).and_return("short".b)
      end

      it 'raises an error if pubkey hash is not 20 bytes' do
        expect { address.get }.to raise_error(RuntimeError, /Invalid pubkey hash length/)
      end
    end
  end
end
