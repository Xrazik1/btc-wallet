# frozen_string_literal: true

require 'net/http'
require 'json'

module Api
  class Blockstream
    BASE_URL = 'https://blockstream.info/signet/api'

    def fetch_tx(txid)
      uri = URI("#{BASE_URL}/tx/#{txid}")
      response = Net::HTTP.get_response(uri)

      raise "HTTP error: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body, symbolize_names: true)
    rescue JSON::ParserError
      raise "Invalid JSON response: #{response.body}"
    end
  end
end
