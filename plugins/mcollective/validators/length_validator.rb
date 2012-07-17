module MCollective
  module Validators
    class LengthValidator
      attr_accessor :validator, :key, :validation

      def initialize(key, validator, validation)
        @validator = validator
        @key = key
        @validation = validation
      end

      def validate
        if validator.size > validation
          raise DDLValidationError, "Input #{key} is longer than #{validation} character(s)"
        end
      end
    end
  end
end
