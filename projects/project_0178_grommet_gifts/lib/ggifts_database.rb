# frozen_string_literal: true

def categories_from_db
  categoies = {}
  GrommetGiftsCategories.all().each { |cat| categoies[cat.id] = cat.category_url }
  categoies
end


def get_existing_gifts(product_ids)
  existing_ids = []
  GrommetGiftsProducts.where(id:product_ids).map { |product| existing_ids.push(product.id) }
  existing_ids
end


def add_new_category_to_product(product_id, category_id)
  existing = GrommetGiftsProductCategories.where(product_id:product_id).where(product_category_id: category_id)[0]
  if existing.nil?
    GrommetGiftsProductCategories.insert({product_id:product_id, product_category_id: category_id})
  end
end

