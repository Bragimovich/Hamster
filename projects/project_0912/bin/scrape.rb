# frozen_string_literal: true

require_relative '../lib/making_story'
require_relative '../models/congressional_record_journals'
require_relative '../models/congressional_record_departaments'
require_relative '../models/congressional_record_senate'
require_relative '../models/congressional_record_house_member'


def scrape(options)
  if @arguments[:story_clean]
    clean_text
  elsif @arguments[:story_count_p]
    count_paragraphs
  elsif @arguments[:story]
    p 'nothing'
  elsif @arguments[:departaments]
    get_departaments
  elsif @arguments[:senate]
    get_senators
  elsif @arguments[:hp]
    get_house_members
  elsif @arguments[:update]
    update_at_days = @arguments[:update] unless @arguments[:update].class==TrueClass
    p update_at_days
    get_departaments(update_at_days)
    get_senators(update_at_days)
    get_house_members(update_at_days)
  end
end
