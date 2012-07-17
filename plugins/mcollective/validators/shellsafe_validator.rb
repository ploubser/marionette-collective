module MCollective
  module Validators
    class ShellsafeValidator
      attr_accessor :validator, :key

      def initialize(key, validator)
        @validator = validator
        @key = key
      end

      def validate
        raise DDLValidationError, "#{@key} should be a String" unless @validator.is_a?(String)

        ['`', '$', ';', '|', '&&', '>', '<'].each do |chr|
          raise DDLValidationError, "#{@key} should not have #{chr} in it" if @validator.match(Regexp.escape(chr))
        end
      end
    end
  end
end
