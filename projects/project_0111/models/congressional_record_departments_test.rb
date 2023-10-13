# frozen_string_literal: true

class CongressionalRecordDepartmentsKeywords < ActiveRecord::Base
  self.table_name = 'congressional_record_departments_keywords_test'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalRecordArticleToDepartmentsKeywords < ActiveRecord::Base
  self.table_name = 'congressional_record_article_to_departments_keywords_test'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end