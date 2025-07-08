# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Utils::Bitcoin do
  describe '.sats_to_btc' do
    it 'returns 0 when sats is 0' do
      expect(described_class.sats_to_btc(0)).to eq(0)
    end

    it 'converts integer sats to float btc correctly' do
      expect(described_class.sats_to_btc(100_000_000)).to eq(1.0)
      expect(described_class.sats_to_btc(50_000_000)).to eq(0.5)
      expect(described_class.sats_to_btc(1)).to eq(0.00000001)
    end

    it 'converts string input to float btc' do
      expect(described_class.sats_to_btc('25000000')).to eq(0.25)
    end
  end

  describe '.btc_to_sats' do
    it 'converts float btc to integer sats' do
      expect(described_class.btc_to_sats(1.0)).to eq(100_000_000)
      expect(described_class.btc_to_sats(0.5)).to eq(50_000_000)
      expect(described_class.btc_to_sats(0.00000001)).to eq(1)
    end

    it 'converts string input to integer sats' do
      expect(described_class.btc_to_sats("0.25")).to eq(25_000_000)
    end

    it 'handles rounding down on float input' do
      expect(described_class.btc_to_sats(0.999999999)).to eq(99_999_999)
    end
  end
end
