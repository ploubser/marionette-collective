module MCollective
  module Validators
    class Ipv6addressValidator
      require 'ipaddr'

      attr_accessor :validator, :key

      def initialize(key, validator)
        @validator = validator
        @key = key
      end

      def validate
        begin
          ip = IPAddr.new(@validator)
          raise DDLValidationError, "#{@key} should be an ipv6 adddress" unless ip.ipv6?
        rescue
          raise DDLValidationError, "#{@key} should be an ipv6 address"
        end
      end
    end
  end
end
