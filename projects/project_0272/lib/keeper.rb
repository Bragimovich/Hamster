require_relative '../models/usda_fsa'

class Keeper
  def initialize
    @all_links = links
    @count     = 0
  end

  attr_reader :all_links, :count

  def save(data)
    UsdaFsa.store(data)
    @count += 1
  end

  private

  def links
    UsdaFsa.all.pluck(:link)
  end
end

