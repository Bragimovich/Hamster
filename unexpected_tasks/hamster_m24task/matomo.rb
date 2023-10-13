# frozen_string_literal: true

require_relative 'powerbi/powerbi_matomo'
require_relative 'model/matomo_site'
require_relative 'model/matomo_log_action'
require_relative 'model/matomo_log_visit'
require_relative 'model/matomo_log_link_visit_action'

module UnexpectedTasks
  module HamsterM24task

    class Matomo
      @auth_mutex = nil

      def self.report message
        Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
      end

      def self.thread_run conf

      end

      def self.run
        #TODO: RUN
        #Get clients key files
        # @auth_mutex = Mutex.new
        # self.config
        # @thread = []
        #
        # @config.each do |conf|
        #   @thread << Thread.new(conf) do |conf|
        PowerBiReportsMatomo.new.run
        #       end
        #       Hamster.report(to: "Mikhail Golovanov", message: "Wait Thread M24", use: :telegram)
        #     end
        #     @thread.each &:join
      end
    end
  end
end
