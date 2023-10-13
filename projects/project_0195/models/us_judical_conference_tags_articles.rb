# frozen_string_literal: true

class USJudicalConferenceTagsArticles < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary

  self.table_name = 'us_judical_conference_tags_article_links'
end


