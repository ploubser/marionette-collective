module MCollective
  module Validators

    @last_load = nil
    @cache_configured = false

    # Loads the validator plugins in a thread safe manner. Validators will only
    # be loaded every 5 minutes
    def self.load_validators
      Cache.setup(:validators) unless @cache_configured

      if load_validators?
        @last_load = Time.now.to_i
        Cache.synchronize(:validators) do
          PluginManager.find_and_load("validators")
        end
      end
    end

    # Returns and instance of the Plugin class from which objects can be created.
    # Valid plugin names are
    #   :valplugin
    #   "valplugin"
    #   "ValpluginValidator"
    def self.[](klass)
      if klass.is_a?(Symbol)
        const_get("#{klass.to_s.capitalize}Validator")
      elsif klass.is_a?(String)
        if klass.match(/.*Validator$/)
          const_get("#{klass}")
        else
          const_get("#{klass.capitalize}Validator")
        end
      end
    end

    def self.method_missing(method, *args, &block)
      validator = Validators[method]

      # Allows validation plugins to be called like module methods : Validator.validate()
      if validator
        validator.new(*args).validate
      else
        super
      end
    end

    def self.load_validators?
      return true if @last_load.nil?

      (@last_load - Time.now.to_i) > 300
    end
  end
end
