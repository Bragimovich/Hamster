require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(options = nil)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def scrape
    download
    store
  end

  def download
    {
      assessment: ['https://www.dpi.nc.gov/2021-22-school-performance-grades'],
      assessment_act: ['https://www.dpi.nc.gov/districts-schools/testing-and-school-accountability/school-accountability-and-reporting/act-reports'],
      assessment_ap_sat: ['https://www.dpi.nc.gov/districts-schools/testing-and-school-accountability/school-accountability-and-reporting/north-carolina-sat-and-ap-reports#SATReports-1554'],
      finances: ['https://www.dpi.nc.gov/districts-schools/district-operations/financial-and-business-services/demographics-and-finances/school-expenditure-data#AnnualExpenditureReportbyDistrictLEA-1691'],
    }.each do |k, v|
      @scraper.scrape_xls_files(k, v)
    end
  end

  def store
    store_prev_years_data
    store_xls_files
  end

  def store_prev_years_data
    @keeper.store_general_info
    @keeper.store_prev_assessment
    @keeper.store_prev_assessment_act
    @keeper.store_prev_assessment_ap_sat
  end

  def store_xls_files
    %w[assessment assessment_act assessment_ap_sat finances].each do |key|
      xls_files = Dir["#{@scraper.store_file_path(key)}/*"]
      xls_files.each do |path|
        case key
        when 'assessment'
          @keeper.store_assessment(path)
        when 'assessment_act'
          @keeper.store_assessment_act(path)
        when 'assessment_ap_sat'
          @keeper.store_assessment_ap_sat(path)
        when 'finances'
          @keeper.store_finances(path)
        end
      end
    end
  end
end
