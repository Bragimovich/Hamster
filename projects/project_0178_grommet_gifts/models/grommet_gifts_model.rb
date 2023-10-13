# frozen_string_literal: true

class GrommetGiftsCategories < ActiveRecord::Base
  self.table_name = 'grommet_gifts_categories'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class GrommetGiftsProductCategories < ActiveRecord::Base
  self.table_name = 'grommet_product_categories'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class GrommetGiftsProducts < ActiveRecord::Base
  self.table_name = 'grommet_products'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class GrommetProductKeywords < ActiveRecord::Base
  self.table_name = 'grommet_product_keywords'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class GrommetProductToKeyword < ActiveRecord::Base
  self.table_name = 'grommet_product_to_keyword'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end