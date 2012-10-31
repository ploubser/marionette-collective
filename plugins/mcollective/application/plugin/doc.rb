module MCollective
  class Application::Plugin<Application
    class Doc

      attr_accessor :configuration

      class << self
        def options
          MCollective::Application::Plugin.option :foo,
            :description => "The new foo option",
            :arguments   => ["--foo"],
            :type        => :boolean
        end

        def usage
          <<-END_OF_USAGE
          This is usage coming from the doc command.
          END_OF_USAGE
        end
      end

      def initialize(config)
        @configuration = config
      end

      def load_plugin_ddl(plugin, type)
        [plugin, "#{plugin}_#{type}"].each do |p|
          ddl = DDL.new(p, type, false)
          if ddl.findddlfile(p, type)
            ddl.loadddlfile
            return ddl
          end
        end
      end

      def run
        known_plugin_types = [["Agents", :agent], ["Data Queries", :data], ["Discovery Methods", :discovery], ["Validator Plugins", :validator]]

        if configuration.include?(:target) && configuration[:target] != "."
          if configuration[:target] =~ /^(.+?)\/(.+)$/
            ddl = load_plugin_ddl($2.to_sym, $1)
          else
            found_plugin_type = nil

            known_plugin_types.each do |plugin_type|
              PluginManager.find(plugin_type[1], "ddl").each do |ddl|
                pluginname = ddl.gsub(/_#{plugin_type[1]}$/, "")
                if pluginname == configuration[:target]
                  abort "Duplicate plugin name found, please specify a full path like agent/rpcutil" if found_plugin_type
                  found_plugin_type = plugin_type[1]
                end
              end
            end

            abort "Could not find a plugin named %s in any supported plugin type" % configuration[:target] unless found_plugin_type

            ddl = load_plugin_ddl(configuration[:target], found_plugin_type)
          end

        puts ddl.help(configuration[:rpctemplate])
        else
          puts "Please specify a plugin. Available plugins are:"
          puts

          load_errors = []

          known_plugin_types.each do |plugin_type|
            puts "%s:" % plugin_type[0]

            PluginManager.find(plugin_type[1], "ddl").each do |ddl|
              begin
                help = DDL.new(ddl, plugin_type[1])
                pluginname = ddl.gsub(/_#{plugin_type[1]}$/, "")
                puts " %-25s %s" % [pluginname, help.meta[:description]]
              rescue => e
                load_errors << [plugin_type[1], ddl, e]
              end
            end

            puts
          end

          unless load_errors.empty?
            puts "Plugin Load Errors:"

            load_errors.each do |e|
              puts " %-25s %s" % ["#{e[0]}/#{e[1]}", Util.colorize(:yellow, e[2])]
            end
          end
        end
      end
    end
  end
end
