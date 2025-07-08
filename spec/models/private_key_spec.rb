# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Models::PrivateKey do
  let(:key_path) { Models::PrivateKey::PRIVATE_KEY_PATH }
  let(:private_key)  { described_class.new }

  before do
    @original_key = File.read(key_path).strip if File.exist?(key_path)
    File.delete(key_path) if File.exist?(key_path)
  end

  after do
    if @original_key
      File.write(key_path, @original_key)
    elsif File.exist?(key_path)
      File.delete(key_path)
    end
  end

  describe '#get' do
    context 'when key file does not exist' do
      it 'generates a new private key' do
        key = private_key.get

        expect(key).to be_a(String)
        expect(key).to match(/\A[0-9a-f]{64}\z/)
        expect(File.exist?(key_path)).to be true
        expect(File.read(key_path).strip).to eq(key)
      end
    end

    context 'when key file exists' do
      it 'returns the same private key from file' do
        first = private_key.get
        second = private_key.get

        expect(first).not_to be_nil
        expect(second).to eq(first)
        expect(File.read(key_path).strip).to eq(first)
      end

      it 'does not generate it again' do
        private_key.get
        expect(private_key).not_to receive(:generate_and_store)
        private_key.get
      end
    end
  end
end
