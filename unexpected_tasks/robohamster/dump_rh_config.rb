require_relative 'rh_tables/_config'

module UnexpectedTasks
  module Robohamster
    class DumpRhConfig
      def self.run(**options)
        if options[:open]
          self.open_from_db(options[:config])
        else
          self.dump_to_db(options[:config])
        end
      end

      def self.dump_to_db(config)
        path_to_config = "../configs/#{config}.yml"
        yaml_config = YAML.load_file(path_to_config)

        yaml_dumped_config = YAML.dump(yaml_config)

        config_to_db = {
          rh_name:         config,
          rh_task:         yaml_config["scrape_task"],
          data_source_url: yaml_config["url"],
          version:         yaml_config["version"],
          requester:       yaml_config["requester"],
          config_yml:      yaml_dumped_config
        }
        RH_Configs.insert(config_to_db)
      end

      def self.open_from_db(config)
        rh_config = RH_Configs.where(rh_name:config).first
        return 0 if rh_config.nil?
        YAML.load(rh_config.config_yml)
      end


    end
  end
end

