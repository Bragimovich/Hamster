# frozen_string_literal: true

class WordsForMatching < ActiveRecord::Base
  self.table_name = 'congressional_record_words_for_matching'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class WordsMatched < ActiveRecord::Base
  self.table_name = 'congressional_record_words_matched'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalLegislationTexts < ActiveRecord::Base
  self.table_name = 'congressional_legislation_texts'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class CongressionalLegislationTexts < ActiveRecord::Base
  self.table_name = 'congressional_legislation_texts'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class CongressionalRecordJournals < ActiveRecord::Base
  self.table_name = 'congressional_record_journals'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
