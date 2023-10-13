# frozen_string_literal: true

class CongressionalRecordHouseMembers < ActiveRecord::Base
  self.table_name = 'congressional_record_house_rp_members'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class USCongressHouseMembers < ActiveRecord::Base
  self.table_name = 'us_congress_house_members'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalRecordArticleToHouseMember < ActiveRecord::Base
  self.table_name = 'congressional_record_article_to_house_member'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end