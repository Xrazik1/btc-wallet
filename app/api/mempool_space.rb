# frozen_string_literal: true

require 'net/http'
require 'json'

module Api
  class MempoolSpace
    BASE_URL = 'https://mempool.space/signet/api'

    def fetch_utxos(address)
      url = URI("#{BASE_URL}/address/#{address}/utxo")

      response = Net::HTTP.get_response(url)

      JSON.parse(response.body).symbolize_keys
    rescue JSON::ParserError
      raise RuntimeError, "Invalid JSON response: #{response.body}"
    rescue => e
      raise RuntimeError, "Failed to fetch UTXOs: #{e.message}"
    end

    def send_raw_transaction(raw_tx_hex)
      uri = URI("#{BASE_URL}/tx")

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'text/plain' })
        request.body = raw_tx_hex

        response = http.request(request)

        raise RuntimeError, "Broadcast failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        response.body.strip
      end
    end
  end
end
