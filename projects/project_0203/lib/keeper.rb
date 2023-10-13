require_relative '../models/natural_resources'

class Keeper
  SOURCE_URL = 'https://naturalresources.house.gov/news/documentquery.aspx?DocumentTypeID=1634'
  def initialize
    @count = 0
  end

  attr_reader :count

  def link_exist?(link)
    !NaturalResources.find_by(link: link).nil?
  end

  def save_news(data)
    data[:data_source_url] = SOURCE_URL
    NaturalResources.store(data)
    @count += 1
  end
end
