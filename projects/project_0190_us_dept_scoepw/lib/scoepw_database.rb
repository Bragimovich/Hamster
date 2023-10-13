# frozen_string_literal: true

def db_model(type)
  case type
  when :news
    SCOEPWNews
  when :pr
    SCOEPWPress
  end
end

def insert_to_db(news_to_db, type=:news)
  db_model(type).insert_all(news_to_db)
end

def get_existing_links(links, type=:news)
  existing_links = []
  lawyers = db_model(type).where(link:links)
  lawyers.each {|row| existing_links.push(row[:link])}
  existing_links
end

