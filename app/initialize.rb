# frozen_string_literal: true

require 'bundler/setup'

require_relative 'constants'
require_relative 'errors'

["services", "models", "utils", "api"].each do |dir|
  Dir[File.join(__dir__, "./#{dir}/**/*.rb")].each { |file| require file }
end
