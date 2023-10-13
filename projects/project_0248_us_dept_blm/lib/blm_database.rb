# frozen_string_literal: true


def insert_to_db(news_to_db)
  begin
    BLM.insert_all(news_to_db)
  rescue
    news_to_db.each do |news|
      BLM.insert(news)
    end
  end
end

def get_existing_links(links)
  existing_links = []
  lawyers = BLM.where(link:links)
  lawyers.each {|row| existing_links.push(row[:link])}
  existing_links
end


