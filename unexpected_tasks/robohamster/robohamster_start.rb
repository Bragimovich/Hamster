require_relative 'dump_rh_config'

module UnexpectedTasks
  module Robohamster
    class RobohamsterStart
      def self.run(**options)
        config = options[:config] || 'site_config_us_secret_service'

        config_hash = self.config(config)
        update = !options[:update].nil?
        scr = RoboHamsterScraper.new()
        scr.robohamster(config_hash, update)
      end


      def self.config(config)
        config_hash = DumpRhConfig.open_from_db(config)
        DumpRhConfig.dump_to_db(config) if config_hash==0
        config_hash = DumpRhConfig.open_from_db(config)
        raise "#{config_hash} is not find in DB and in ../configs/" if config_hash==0
        config_hash
      end

    end
  end
end