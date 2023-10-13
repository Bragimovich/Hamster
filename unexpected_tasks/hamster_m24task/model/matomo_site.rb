class MatomoSite < ActiveRecord::Base
  establish_connection(Storage.use(host: :dbRS, db: :mat))
  self.table_name = 'matomo_site'
  self.inheritance_column = :_type_disabled
  has_many :la, :class_name => "MatomoLogAction", foreign_key: :idsite
  has_many :lva, :class_name => "MatomoLogLinkVisitAction", foreign_key: :idsite
  has_many :lv, :class_name => "MatomoLogVisit", foreign_key: :idsite


end
