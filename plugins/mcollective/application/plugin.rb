module MCollective
  class Application::Plugin<Application

    sub_commands :doc, :package, :info, :generate

#    autoload :Package, 'plugin/package'
#    autoload :Info, 'plugin/info'
    autoload :Doc, 'plugin/doc'
#    autoload :Generate, 'plugin/generate'

    exclude_argument_sections "common", "filter", "rpc"

    description "MCollective Plugin Application"

    # Going to need to change when options get parsed so we can define them in
    # the subclasses
    usage <<-END_OF_USAGE
A General description of the Plugin usage goes here. Subcommands are
      mco plugin package  --help
      mco plugin info     --help
      mco plugin doc      --help
      mco plugin generate --help
    END_OF_USAGE

    def post_option_parser(configuration)
      if ARGV.length >= 1
        configuration[:action] = ARGV.delete_at(0)
        configuration[:target] = ARGV.delete_at(0) || "."
      end
    end

    def main
      abort "No action specified, please run 'mco help plugin' for help" unless configuration.include?(:action)
      cmd = "#{configuration[:action]}_command"

      if respond_to? cmd
        send cmd
      else
        abort "Invalid action #{configuration[:action]}, please run 'mco help plugin' for help"
      end
    end

#    def package_command
#      Package.new(configuration).run
#    end

    #def info_command
    #  Info.new(some_parameters).run
    #end

    def doc_command
      Doc.new(configuration).run
    end

    #def generate_command
    #  Generate.new(some_parameters).run
    #end

  end
end
