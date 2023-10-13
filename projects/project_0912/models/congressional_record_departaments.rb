# frozen_string_literal: true

class CongressionalRecordDepartments < ActiveRecord::Base
  self.table_name = 'congressional_record_departments'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalRecordDepartmentsMatching < ActiveRecord::Base
  self.table_name = 'congressional_record_departments_matching_names'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalRecordArticleToDepartments < ActiveRecord::Base
  self.table_name = 'congressional_record_article_to_departaments'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

