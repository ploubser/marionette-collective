module MCollective
  class Application::Plugin<Application

    exclude_argument_sections "common", "filter", "rpc"

    description "MCollective Plugin Application"
    usage <<-END_OF_USAGE
mco plugin package [options] <directory>
       mco plugin info <directory>
       mco plugin doc <plugin>
       mco plugin doc <type/plugin>

          info : Display plugin information including package details.
       package : Create all available plugin packages.
           doc : Display documentation for a specific plugin.
    END_OF_USAGE

    option  :pluginname,
            :description => "Plugin name",
            :arguments => ["-n", "--name NAME"],
            :type => String

    option :postinstall,
           :description => "Post install script",
           :arguments => ["--postinstall POSTINSTALL"],
           :type => String

    option :preinstall,
           :description => "Pre install script",
           :arguments => ["--preinstall PREINSTALL"],
           :type => String

    option :iteration,
           :description => "Iteration number",
           :arguments => ["--iteration ITERATION"],
           :type => String

    option :vendor,
           :description => "Vendor name",
           :arguments => ["--vendor VENDOR"],
           :type => String

    option :pluginpath,
           :description => "MCollective plugin path",
           :arguments => ["--pluginpath PATH"],
           :type => String

    option :mccommon,
           :description => "Set the mcollective common package that the plugin depends on",
           :arguments => ["--mc-common-pkg PACKAGE"],
           :type => String

    option :mcserver,
           :description => "Set the mcollective server package that the plugin depends on",
           :arguments => ["--mc-server-pkg PACKAGE"],
           :type => String

    option :mcclient,
           :description => "Set the mcollective client package that the plugin depends on",
           :arguments => ["--mc-client-pkg PACKAGE"],
           :type =>String

    option :dependency,
           :description => "Adds a dependency to the plugin",
           :arguments => ["--dependency DEPENDENCIES"],
           :type => :array

    option :format,
           :description => "Package output format. Defaults to rpmpackage or debpackage",
           :arguments => ["--format OUTPUTFORMAT"],
           :type => String

    option :sign,
           :description => "Embed a signature in the package",
           :arguments => ["--sign"],
           :type => :boolean

    option :rpctemplate,
           :description => "Template to use.",
           :arguments => ["--template HELPTEMPLATE"],
           :type => String

    # Handle alternative format that optparser can't parse.
    def post_option_parser(configuration)
      if ARGV.length >= 1
        configuration[:action] = ARGV.delete_at(0)

        configuration[:target] = ARGV.delete_at(0) || "."
      end
    end

    # Display info about plugin
    def info_command
      plugin = prepare_plugin
      packager = PluginPackager["#{configuration[:format].capitalize}Packager"]
      packager.new(plugin).package_information
    end

    # Package plugin
    def package_command
      if configuration[:sign] && Config.instance.pluginconf.include?("debian_packager.keyname")
        configuration[:sign] = Config.instance.pluginconf["debian_packager.keyname"]
        configuration[:sign] = "\"#{configuration[:sign]}\"" unless configuration[:sign].match(/\".*\"/)
      end

      plugin = prepare_plugin
      (configuration[:pluginpath] = configuration[:pluginpath] + "/") if (configuration[:pluginpath] && !configuration[:pluginpath].match(/^.*\/$/))
      packager = PluginPackager["#{configuration[:format].capitalize}Packager"]
      packager.new(plugin, configuration[:pluginpath], configuration[:sign], configuration[:verbose]).create_packages
    end

    # Show application list and plugin help
    def doc_command
      known_plugin_types = [["Agents", :agent], ["Data Queries", :data]]

      if configuration.include?(:target) && configuration[:target] != "."
        if configuration[:target] =~ /^(.+?)\/(.+)$/
          plugin_type = $1.to_sym
          plugin_name = $2

          # Agents are just called 'agent' but newer plugin types are
          # called plugin_plugintype for example facter_facts etc so
          # this will first try the old way then the new way.
          begin
            ddl = DDL.new(plugin_name, plugin_type)
          rescue
            ddl = DDL.new("#{plugin_name}_#{plugin_type}", plugin_type)
          end
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

          abort "Could not find a plugin named %s in any supported plugin type" % plugin_type[1] unless found_plugin_type
          begin
            ddl = DDL.new(configuration[:target], found_plugin_type)
          rescue
            ddl = DDL.new("#{configuration[:target]}_#{found_plugin_type}", found_plugin_type)
          end
        end

        puts ddl.help(configuration[:rpctemplate])
      else
        puts "Please specify a plugin. Available plugins are:"
        puts

        known_plugin_types.each do |plugin_type|
          puts "%s:" % plugin_type[0]

          PluginManager.find(plugin_type[1], "ddl").each do |ddl|
            help = DDL.new(ddl, plugin_type[1])
            pluginname = ddl.gsub(/_#{plugin_type[1]}$/, "")
            puts "  %-15s %s" % [pluginname, help.meta[:description]]
          end

          puts
        end
      end
    end

    # Creates the correct package plugin object.
    def prepare_plugin
        plugintype = set_plugin_type unless configuration[:plugintype]
        configuration[:format] = "ospackage" unless configuration[:format]
        PluginPackager.load_packagers
        plugin_class = PluginPackager[configuration[:plugintype]]
        configuration[:dependency] = configuration[:dependency][0].split(" ") if configuration[:dependency] && configuration[:dependency].size == 1
        mcodependency = {:server => configuration[:mcserver],
                         :client => configuration[:mcclient],
                         :common => configuration[:mccommon]}

        plugin_class.new(configuration[:target], configuration[:pluginname],
                         configuration[:vendor], configuration[:preinstall],
                         configuration[:postinstall], configuration[:iteration],
                         configuration[:dependency], mcodependency , plugintype)
    end

    def directory_for_type(type)
      File.directory?(File.join(configuration[:target], type))
    end

    # Identify plugin type if not provided.
    def set_plugin_type
      if directory_for_type("agent") || directory_for_type("application")
        configuration[:plugintype] = "AgentDefinition"
        return "Agent"
      elsif directory_for_type(plugintype = identify_plugin)
        configuration[:plugintype] = "StandardDefinition"
        return plugintype
      else
        raise RuntimeError, "target directory is not a valid mcollective plugin"
      end
    end

    # If plugintype is StandardDefinition, identify which of the special
    # plugin types we are dealing with based on directory structure.
    # To keep it simple we limit it to one type per target directory.
    def identify_plugin
      plugintype = Dir.glob(File.join(configuration[:target], "*")).select do |file|
        File.directory?(file) && file.match(/(connector|facts|registration|security|audit|pluginpackager|data)/)
      end

      raise RuntimeError, "more than one plugin type detected in directory" if plugintype.size > 1
      raise RuntimeError, "no plugins detected in directory" if plugintype.size < 1

      stripdir = configuration[:target] == "." ? "" : configuration[:target]
      plugintype.first.gsub(/\.|\/|#{stripdir}/, "")
    end

    def main
        abort "No action specified, please run 'mco help plugin' for help" unless configuration.include?(:action)

        cmd = "#{configuration[:action]}_command"

        if respond_to? cmd
          send cmd
        else
          abort "Invalid action #{configuration[:action]}, please run 'mco help plugin' for help."
        end
    end
  end
end
