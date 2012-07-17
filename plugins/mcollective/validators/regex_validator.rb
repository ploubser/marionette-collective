module MCollective
  module Validators
    class RegexValidator
      attr_accessor :validator, :key, :validation

      def initialize(key, validator, validation)
        @validator = validator
        @key = key
        @validation = validation
      end

      def validate
        raise DDLValidationError, "#{@key} should match #{@validation}" unless @validator.match(@validation)
      end
    end
  end
end
