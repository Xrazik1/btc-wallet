# frozen_string_literal: true

require 'securerandom'

module Models
  class PrivateKey
    PRIVATE_KEY_PATH = File.expand_path('../db/private-key.txt', __dir__)

    def get
      return File.read(PRIVATE_KEY_PATH).strip if File.exist?(PRIVATE_KEY_PATH)

      generate_and_store
    end

    private

    def generate_and_store
      hex = SecureRandom.hex(32)
      File.write(PRIVATE_KEY_PATH, hex)

      hex
    end
  end
end
