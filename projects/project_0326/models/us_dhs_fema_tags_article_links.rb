class UsDhsFemaTagsArticleLinks < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
end
