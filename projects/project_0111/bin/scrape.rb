# frozen_string_literal: true

require_relative '../lib/congress_scraper'
require_relative '../lib/congress_parser'

require_relative '../lib/congress_database'
require_relative '../models/congressional_record_journals'

require_relative '../lib/making_story'
require_relative '../models/congressional_record_journals'
require_relative '../models/congressional_record_departments'
require_relative '../models/congressional_record_senate'
require_relative '../models/congressional_record_house_member'

require_relative '../models/congressional_record_departments_test'


def scrape(options)
  if @arguments[:update]
    Scraper.new(1)

    update_at_days = 5
    update_at_days = @arguments[:update] unless @arguments[:update].class==TrueClass
    p update_at_days
    get_departaments(update_at_days)
    get_senators(update_at_days, 0)
    #get_house_members(update_at_days, 0)
  elsif @arguments[:match]
    update_at_days = 5
    update_at_days = @arguments[:days] if @arguments[:days]
    full=0
    full = 1 if @arguments[:full]
    if @arguments[:match]=='hm'
      get_house_members(update_at_days, full)
    elsif @arguments[:match]=='s'
      get_senators(update_at_days, full)
    elsif @arguments[:match]=='d'
      get_departaments(update_at_days)
    else
      get_departaments(update_at_days)
      get_senators(update_at_days, full)
      get_house_members(update_at_days, full)
    end
  elsif @arguments[:match_full]
    update_at_days = 30
    get_departaments(update_at_days)
    get_senators(update_at_days)
    get_house_members(update_at_days)
  elsif @arguments[:match_test]

    get_departments_test()

  elsif @arguments[:clean]
    clean_text
  elsif @arguments[:old]
    update = @arguments[:old]*-1
    if @arguments[:test]
      Scraper.new(update, 1)
    else
      Scraper.new(update, 0)
    end
  elsif @arguments[:del]
    delete_similar_links(year=@arguments[:del])
  else
    Scraper.new(0)
  end


end
