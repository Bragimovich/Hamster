# frozen_string_literal: true

def insert_to_db(news_to_db)
  HSCR.insert_all(news_to_db)
end

def get_existing_links(links)
  existing_links = []
  lawyers = HSCR.where(link:links)
  lawyers.each {|row| existing_links.push(row[:link])}
  existing_links
end

