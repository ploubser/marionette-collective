module MCollective
  module Functions
    def self.load_functions
      PluginManager.find_and_load("functions")
    end

    def self.[](klass)
      const_get("#{klass}")
    end

    def self.summarize(action, ddl, data)
      result = []
      function = nil
      param = nil

      summary = ddl.entities[action][:output].reduce([]) do |container, output|
        if output[1].keys.include?(:summarize)
          container << output[1][:summarize]
        end
      end

      return if summary.empty?

      summary.each do |sum|
        function, params = sum.split('(')
        param, description = params.split(',')
        param = param.gsub("'", "")
        description = description.gsub(/'|\)/, "")

        data_values = data.map{|x| x.results[:data][param.to_sym]}
        result << {param.to_sym =>
                      {:value => Functions["ClientFunctions"].new.execute(function.to_sym, data_values),
                       :description => description,
                       :type => "value"}}
      end

      result
    end
  end
end
