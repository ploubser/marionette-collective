module MCollective
  module Validators
    class Ipv4addressValidator
      require 'ipaddr'

      attr_accessor :key, :validator

      def initialize(key, validator)
        @validator = validator
        @key = key
      end

      def validate
        begin
          ip = IPAddr.new(@validator)
          raise DDLValidationError, "#{@key} should be an ipv4 adddress" unless ip.ipv4?
        rescue
          raise DDLValidationError, "#{@key} should be an ipv4 address"
        end
      end

    end
  end
end
