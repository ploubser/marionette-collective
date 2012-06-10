module MCollective
  module Functions
    class ClientFunctions
      attr_accessor :functions

      def initialize
        @functions = {}
        load_client_functions
      end

      def load_client_functions
       function_path = File.join(File.dirname(__FILE__), "client_functions")
        Dir.new(function_path).each do |file|
          if file.match(/.rb/)
            instance_eval File.read(File.join(function_path, file))
          end
        end
      end

      def method_missing(mname, *args, &block)
        if mname == :function
          @functions[args[0].to_sym] = block
        else
          raise "Cannot load function '#{mname}'."
        end
      end

      def execute(function_name, param_array)
        @functions[function_name.to_sym].call(param_array)
      end
    end
  end
end
