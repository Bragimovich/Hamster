# frozen_string_literal: true

class CongressionalRecordSenateMembers < ActiveRecord::Base
  self.table_name = 'congressional_record_senate_members'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class USCongressSenateMembers < ActiveRecord::Base
  self.table_name = 'us_congress_senate_members'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalRecordArticleToSenateMember < ActiveRecord::Base
  self.table_name = 'congressional_record_article_to_senate_member'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end