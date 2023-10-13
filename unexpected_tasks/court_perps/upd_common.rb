# frozen_string_literal: true

require_relative 'upd_common/db_store'
require_relative 'upd_common/common_model'
module UnexpectedTasks
  module CourtPerps
    class UpdCommon

      def self.log(message)
        message = "#UPD COMMON(711): " + message.to_s
        Hamster.report(to: "Mikhail Golovanov", message: message, use: :slack)
      end


      def self.run(**options)
        log("start")
        DBStore.new.run
        log("finish")
      end
    end

  end
end

