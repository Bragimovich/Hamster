# frozen_string_literal: true

require_relative 'lib/manager_wf'
require_relative 'lib/scraper_wf'
require_relative 'lib/parser_wf'
require_relative 'lib/keeper_wf'
require_relative 'models/wf_db_models'

def scrape(options)
  ManagerWF.new(**options)

end


