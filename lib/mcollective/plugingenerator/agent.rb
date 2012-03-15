module MCollective
  module PluginGenerator
    class Agent
      require 'erb'
      require 'readline'

      attr_accessor :plugin_name, :ddl, :meta

      def initialize(name, params, filegiven = false)
        @plugin_name = name
        @actions = []
        @meta = {:description => nil,
                 :author => nil,
                 :license => nil,
                 :version => nil,
                 :url => nil,
                 :timeout => nil}

        if filegiven
          @meta = params["meta"]
          @actions = params["actions"]
        else
          get_metadata
          get_actions
        end

        create_agent
      end

      def get_binding
        binding
      end

      def create_agent
        puts "Creating #{@plugin_name} agent..."

        FileUtils.mkdir_p "#{@plugin_name}/agent"
        add_ddl_actions
        add_agent_actions
        puts "...done"
      end

      def add_ddl_actions
        @ddl = StringIO.new
        @ddl.puts ERB.new(File.read(File.join(File.dirname(__FILE__), "templates", "ddl.erb"))).result(self.get_binding)
        @ddl.puts

        @actions.each do |action|
          @ddl.puts "action \"#{action[:name]}\", :description => \"#{action[:description]}\" do"
          @ddl.puts "  %s" % "display :#{action[:display]}"
          @ddl.puts

          action[:inputs].each do |input|
            @ddl.puts "  %s" % "input :#{input[:name]},"
            name = input.delete(:name)
            input.keys.each_with_index do |key, i|
              input[key] = "\"#{input[key]}\"" unless key == "type" || key == "maxlength"
              input[key] = ":#{input[key]}" if key == "type"
              @ddl.puts "    %s" % ":#{key} => #{input[key]}" +  ((i == input.keys.size - 1) ? "" : ",")
            end
            @ddl.puts
            input[:name] = name
          end if action[:inputs]

          action[:outputs].each do |output|
            @ddl.puts "  %s" % "output :#{output[:name]},"
            name = output.delete(:name)
            output.keys.each_with_index do |key, i|
              @ddl.puts "    %s" % ":#{key} => \"#{output[key]}\"" + ((i == output.keys.size - 1) ? "" : ",")
            end
            @ddl.puts
            output[:name] = name
          end if action[:outputs]

        @ddl.puts "end"
        @ddl.puts
        end

        File.open("#{@plugin_name}/agent/#{@plugin_name}.ddl", "w") {|f| f.puts @ddl.string}
      end

      def add_agent_actions
        @agent = StringIO.new
        @agent.puts  ERB.new(File.read(File.join(File.dirname(__FILE__), "templates", "agent.erb"))).result(self.get_binding)
        actions = StringIO.new
        @actions.each do |action|
          actions.puts "      ##{action[:description]}"
          actions.puts "      action \"#{action[:name]}\" do"
          action[:inputs].each do |input|
            actions.puts "        validate :#{input[:name]}, #{input[:type].capitalize}"
          end if action[:inputs]
          actions.puts "      end"
          actions.puts
        end

        @agent = @agent.string.gsub("# Actions\n", actions.string)
        File.open("#{@plugin_name}/agent/#{@plugin_name}.rb", "w") {|f| f.puts @agent}
      end

      def get_metadata
        puts "Gathering Plugin Metadata. Enter 'exit' at any time to quit."
        puts "----------------------------"
        puts "Description?"
        @meta[:description] = read
        puts "Author?"
        @meta[:author] = read
        puts "License?"
        @meta[:license] = read
        puts "Version?"
        @meta[:version] = read
        puts "URL?"
        @meta[:url] = read
        puts "Timeout?"
        @meta[:timeout] = read
      end

      def get_actions
        @actions += ask_questions("action", [:name, :description, :display]) do |struct|
          struct[:inputs] = ask_questions("input", [:name, :prompt, :description, :type, :validation, :optional, :maxlength])
          struct[:outputs] = ask_questions("output", [:name, :description, :display_as])
        end
      end

      def ask_questions(type, fields)
        container = Array.new
        puts
        puts "Gathering #{type} information. Enter 'done' when you have finished specifying #{type}s"
        puts "--------------------------------------------------------------"

        i = 1
        loop do
          puts "#{type.capitalize}  number #{i}"
          i = i + 1
          puts
          struct = Hash.new
          exitstatus = fields.each do |field|
            puts "#{type.capitalize} : #{field}?"
            line = read
            break(-1) if line == "done"
            struct[field] = line
          end
          break if exitstatus == -1

          if block_given?
            yield struct
          end

          container << struct
        end

        container.flatten
      end

      def read
        val = Readline.readline('> ', true)
        exit! if val == "exit"
        val
      end

    end
  end
end
