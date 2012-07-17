module MCollective
  module Validators
    class ArrayValidator
      attr_accessor :validator, :key, :validation

      def initialize(key, validator, validation)
        @validator = validator
        @key = key
        @validation = validation
      end

      def validate
        raise DDLValidationError, "#{@key} should be one of %s" % [ @validation.join(", ") ] unless @validation.include?(@validator)
      end
    end
  end
end
