# frozen_string_literal: true

require_relative '../lib/manager'
HEADERS = {
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language: 'en-US,en;q=0.5',
  connection: 'keep-alive',
  upgrade_insecure_requests: '1'
}.freeze
ERROR = 'ERROR'
API_URL = 'https://www.courtlistener.com/api/rest/v3/'
RECORDS_PER_PAGE = 20
MAX_PAGES = 100
LIMIT = RECORDS_PER_PAGE * MAX_PAGES
MIN_ID_2021 = 4648609 # minimal id for opinions after 2021-01-01T00:00:00
TABLES =
  %w( cl_courts
      cl_schools
      cl_judge_job
      cl_judge_info
      cl_judge_schools
      cl_judge_political_affiliation)
SCHOOL_LINKS =
  [ "#{API_URL}schools/?format=json&name__contains=y&order_by=id",
    "#{API_URL}schools/?format=json&name__contains=y&order_by=-id",
    "#{API_URL}schools/?format=json&name__contains!=y&order_by=id",
    "#{API_URL}schools/?format=json&name__contains!=y&order_by=-id"]

def scrape(options)
  manager = CourtListener.new
  manager.parse_by_api if options[:parse] || options[:auto]
  manager.store if options[:store] || options[:auto]
rescue StandardError => e
  report to: 'U03F2H0PB2T', message: "courtlistener EXCEPTION: #{e}"
  puts ['*'*77,  e.backtrace]
  exit 1
end
