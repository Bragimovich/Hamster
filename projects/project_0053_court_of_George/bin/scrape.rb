# frozen_string_literal: true
require_relative '../lib/get_data'
require_relative '../lib/RequestSite'

def scrape(options)
  if @arguments[:download] or @arguments[:update]
    george_court = Parse.new()
    george_court.manager
    return
  end

  #url_get = 'https://scweb.gasupreme.org:8088/results_one_record.php?caseNumber=S17A0151'
  #p get_site(url_get)
  #
  #q = GetCase.new('S16A1487')
  #p q.get_case_info
  #p q.get_case_activities


end
