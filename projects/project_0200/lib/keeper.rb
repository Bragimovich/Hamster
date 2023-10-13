require_relative '../models/us_dept_energy_and_commerce_categories'
require_relative '../models/us_dept_energy_and_commerce_categories_article_links'
require_relative '../models/us_dept_energy_and_commerce'
require_relative '../models/us_dept_energy_and_commerce_runs'

class Keeper
  def initialize
    @run_object = RunId.new(UsDeptEnergyAndCommerceRuns)
    @run_id = @run_object.run_id
  end

  def store(hash)
    hash = replace_empty_strings_with_nil(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    # remove nil key value pairs in hash
    hash = hash.reject{|k,v| k.nil?}
    check = UsDeptEnergyAndCommerce.where(link: hash[:link], deleted: 0).as_json.first
    if check && check['md5_hash'] == hash[:md5_hash]
      UsDeptEnergyAndCommerce.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      UsDeptEnergyAndCommerce.mark_deleted(check['id'])
      UsDeptEnergyAndCommerce.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      UsDeptEnergyAndCommerce.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def store_categories(list_of_categories)
    list_of_categories.each do |category|
      next if UsDeptEnergyAndCommerceCategories.exists?(category: category)
      UsDeptEnergyAndCommerceCategories.insert({category: category})
    end
  end

  def get_category_id(category)
    UsDeptEnergyAndCommerceCategories.where(category: category)&.first&.id
  end
  
  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end

  def store_article_link_and_its_categories(hash)
    UsDeptEnergyAndCommerceCategoriesArticleLinks.insert(hash)
  end
  
  def replace_empty_strings_with_nil(hash)
    new_hash = {}
    hash.each do |key, value|
      new_hash[key] = value.presence || nil
    end
    new_hash
  end 

  def finish
    @run_object.finish
  end
end