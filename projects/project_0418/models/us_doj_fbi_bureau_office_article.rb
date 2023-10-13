# frozen_string_literal: true

class UsDojFbiBureauOfficeArticle < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'us_doj_fbi_bureau_office_article'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end