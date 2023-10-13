# frozen_string_literal: true

class Politico < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'politico'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end

class PoliticoCategory < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'politico_categories'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end

class PoliticoAuthor < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'politico_authors'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end

class PoliticoTag < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'politico_tags'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end

class PoliticoCategoryArticleLink < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'politico_categories_article_links'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end

class PoliticoAuthorArticleLink < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'politico_authors_article_links'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end

class PoliticoTagArticleLink < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'politico_tags_article_links'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end

class PoliticoRuns < ActiveRecord::Base
    establish_connection(Storage[host: :db02, db: :press_releases])
    self.table_name = 'politico_runs'
    self.inheritance_column = :_type_disabled
    self.logger = Logger.new(STDOUT)
end
