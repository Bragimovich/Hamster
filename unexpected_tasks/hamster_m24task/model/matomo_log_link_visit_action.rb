class MatomoLogLinkVisitAction < ActiveRecord::Base
  self.table_name = 'matomo_log_link_visit_action'
  establish_connection(Storage.use(host: :dbRS, db: :mat))


  def self.log_values
    self.connection.execute("SELECT MAX(idlink_va) AS idlink_max, MIN(idlink_va) AS idlink_min, COUNT(idlink_va) AS idlink_count FROM matomo_log_link_visit_action").map do |item|
      {
        :idlink_max => item[0],
        :idlink_min => item[1],
        :idlink_count => item[2]
      }
    end

  end
end
