# frozen_string_literal: true

class Hash
  def symbolize_keys
    each_with_object({}) do |(k, v), result|
      key = k.is_a?(String) ? k.to_sym : k
      result[key] = v.respond_to?(:symbolize_keys) ? v.symbolize_keys : v
    end
  end
end

class Array
  def symbolize_keys
    map { |item| item.respond_to?(:symbolize_keys) ? item.symbolize_keys : item }
  end
end
