# frozen_string_literal: true

require 'ecdsa'
require 'digest'
require 'base58'

module Models
  class Address
    ADDRESS_PATH = File.expand_path('../db/address.txt', __dir__)

    def get
      return File.read(ADDRESS_PATH).strip if File.exist?(ADDRESS_PATH)

      private_hex = Models::PrivateKey.new.get
      pubkey = compressed_pubkey(private_hex)
      pubkey_hash = hash160(pubkey)

      raise RuntimeError, "Invalid pubkey hash length" unless pubkey_hash.size == 20

      address = encode_signet_p2pkh(pubkey_hash)
      File.write(ADDRESS_PATH, address)

      address
    end

    private

    def compressed_pubkey(hex)
      group = ECDSA::Group::Secp256k1
      priv_bn = hex.to_i(16)

      raise RuntimeError, "Invalid private key" if priv_bn <= 0 || priv_bn >= group.order

      point = group.generator.multiply_by_scalar(priv_bn)

      prefix = point.y.even? ? '02' : '03'
      prefix + point.x.to_s(16).rjust(64, '0')
    end

    def hash160(pubkey_hex)
      sha256 = Digest::SHA256.digest([pubkey_hex].pack('H*'))
      Digest::RMD160.digest(sha256)
    end

    def encode_signet_p2pkh(pubkey_hash)
      versioned = "\x6f" + pubkey_hash
      checksum = Digest::SHA256.digest(Digest::SHA256.digest(versioned))[0, 4]

      Base58.binary_to_base58(versioned + checksum, :bitcoin)
    end
  end
end
