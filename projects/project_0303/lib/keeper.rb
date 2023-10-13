require_relative '../models/arpa_e_energy'

class Keeper
  def initialize
    @db_links = get_db_links
    @count    = 0
  end

  attr_reader :db_links, :count

  def save_article(article)
    return if @db_links.include?(article[:link])

    ArpaEEnergy.store(article)
    @count += 1
  end

  private

  def get_db_links
    ArpaEEnergy.all.pluck(:link)
  end
end

