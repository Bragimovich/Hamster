require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester
  YEARS                = [*2011..Date.today.year] * 3
  LINK_NAME            = ['Comma separated value file',
                          'State-to-State Inflow',
                          'State-to-State Outflow'
                         ]
  URL                  = 'https://www.irs.gov'
  URL_MIGRATION        = 'https://www.irs.gov/statistics/soi-tax-stats-migration-data'
  NAME_FILE            = LINK_NAME.map {|phrase| phrase.gsub(/[' '-]/, '_')}
  def download
    scraper = Scraper.new(teg_phrase: LINK_NAME, url_migration: URL_MIGRATION, url: URL)
    links   = scraper.return_link
    scraper.scrape(links)
  end
  def store
    years_tabs          = YEARS.sort
    name_csv            = peon.give_list(subfolder: "csv").sort
    link_s              = LINK * 3 #for 3 tables
    link_s              = link_s.sort
      name_csv.each do |name| general_url      = link_s.delete_at(0)
      year             = years_tabs.delete_at(0)
      years            = [*year..year+1]
      year_file        = years.join('-')
      name_file        = name.split('.')[1]
      keeper           = Keeper.new
      if name_file     == NAME_FILE[0]
        csv            = peon.give(file: "#{year_file}.#{NAME_FILE[0]}.csv.gz", subfolder: "csv") #IRS_gross_migration
        parser         = Parser.new(csv: csv)
        data           = parser.parse_csv(years, general_url)
        keeper.save_csv(IRSGrossMigration, data)
      elsif name_file  == NAME_FILE[1]
        csv_inflow     = peon.give(file: "#{year_file}.#{NAME_FILE[1]}.csv.gz", subfolder: "csv")
        parser_inflow  = Parser.new(csv_inflow_outflow: csv_inflow)
        data_inflow    = parser_inflow.parse_csv_inflow_outflow(years, general_url)
        keeper.save_csv(IRSStateInflow, data_inflow)
      else
        csv_outflow    = peon.give(file: "#{year_file}.#{NAME_FILE[2]}.csv.gz", subfolder: "csv")
        parser_outflow = Parser.new(csv_inflow_outflow: csv_outflow)
        data_outflow   = parser_outflow.parse_csv_inflow_outflow(years, general_url)
        keeper.save_csv(IRSStateOutflow, data_outflow)
      end
    end
  end
end
