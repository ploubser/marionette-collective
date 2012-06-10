module MCollective
  # Change to something better
  class Summarize

    attr_accessor :result_stack, :functions

    def initialize()
      # Populate with parsed results from DDL
      @functions = {}
      @result_stack = {}

      # Here we're adding functions to facilitate testing.
      # This will be replaced by a loader class, possibly using pluginmanager?
      add_some_functions
    end

    def call_function(name, vals)
      @result_stack[name] = @functions[name].call(@result_stack[name], [vals].flatten)
    end

    # Add functions to the function hash. This is a sim of what we're going to be doing in the functions class
    def add_function(name, structure = nil, &block)
      @functions[name.to_sym] = block
      @result_stack[name.to_sym] = structure
    end

    # Display method based on our pictures idea
    def display(picture, result)
      result.each do |r|
        if r.is_a? Hash
          result_string = ""

          r.each_pair do |k,v|
            result_string << picture % [k, v] + "\n"
          end

          return result_string
        elsif result.is_a? Array

        else
          return picture % result
        end
      end
    end

    # For testing purposes only
    def add_some_functions
      add_function :avg do |structure, results|
        structure ||= {:count => 0,
                       :value => 0}

        structure[:count] += results.size
        structure[:value] = results.reduce(structure[:value]){|x,y| x + y} / structure[:count]
        structure
      end

      add_function :summarize do |structure, results|
        structure ||= {:value => { :success => 0,
                                   :failure => 0}}

        results.each do |result|
          if result[:code] == 0
            structure[:success] += 1
          elsif result[:code] = 1
            structure[:failure] += 1
          end
        end
        structure
      end

      add_function :avg_ping do |structure, results|
        structure ||= {:value => 0,
                       :count => 0}

        structure[:count] += results.size
        structure[:value] = results.reduce(structure[:value]){|x,y| x + ((Time.now.to_f - y) * 1000)} / structure[:count]
        structure
      end

      add_function :total do |structure, results|
        structure ||= {:value => {}}
        results.each do |result|
          if structure[:value].keys.include?(result)
            structure[:value][result] += 1
          else
            structure[:value][result] = 1
          end
        end

        structure
      end

    end
  end
end
