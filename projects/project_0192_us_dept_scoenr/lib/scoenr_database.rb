# frozen_string_literal: true

def db_model(type)
  case type
  when :d
    SCOEMRDemocratic
  when :r
    SCOEMRRepublican
  end
end

def insert_to_db(news_to_db, type=:news)
  begin
    db_model(type).insert_all(news_to_db)
  rescue
    news_to_db.each do |news|
      p news[:link]
      db_model(type).insert(news)
    end
  end
end

def get_existing_links(links, type=:news)
  existing_links = []
  lawyers = db_model(type).where(link:links)
  lawyers.each {|row| existing_links.push(row[:link])}
  existing_links
end

