module MCollective
  module Validators
    class TypecheckValidator
      attr_accessor :key, :validator, :validation

      def initialize(key, validator, validation)
        @key = key
        @validator = validator
        @validation = validation
      end

      def validate
        raise DDLValidationError, "#{@key} should be a #{@validation.to_s}" unless check_type
      end

      def check_type
        case @validation
        when :integer
          @validator.is_a?(Fixnum)
        when :float
          @validator.is_a?(Float)
        when :number
          @validator.is_a?(Numeric)
        when :string
          @validator.is_a?(String)
        when :boolean
          [TrueClass, FalseClass].include?(@validator.class)
        else
          false
        end
      end
    end
  end
end
