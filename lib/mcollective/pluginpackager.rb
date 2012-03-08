module MCollective
  module PluginPackager
    # Plugin definition classes
    autoload :Agent, "mcollective/pluginpackager/agent"

    # Package implementation plugins
    def self.load_packagers
      PluginManager.find_and_load("pluginpackager")
    end

    def self.[](klass)
      const_get(klass.capitalize)
    end
  end
end
