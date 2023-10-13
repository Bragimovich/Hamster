# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

require 'fileutils'

class Manager < Hamster::Scraper
  def initialize(options)
    super

    @options = options
    @scraper = Scraper.new
    @parser  = Parser.new

    @keeper = Keeper.new(
      max_buffer_size: @options[:buffer],
      run_model:       'MiCampFinanceRun'
    )
  end

  def run
    Hashie.logger = Logger.new('/dev/null') # Hack for annoying hashie warn
    skip_delete = @options.fetch(:skipdelete, false)
    start_year  = @options.fetch(:startyear, 2016)

    clear_file_storage

    all_dump_url  = 'https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/'
    all_dump_html = @scraper.get_content(all_dump_url)
    cont_files, exp_files = @parser.parse_all_dump_html(all_dump_html)

    cont_files.each do |year, files|
      next if year < start_year

      files.each do |file_name|
        file_url  = "https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/#{file_name}"
        file_path = "#{storehouse}store/#{file_name}"
        @scraper.download_file(file_url, file_path)

        @parser.parse_contribution_file(file_path) do |contribution, contributor|
          contribution[:data_source_url] = file_url
          contributor[:data_source_url] = file_url
          @keeper.save_data('MiCampFinanceContribution', contribution)
          @keeper.save_data('MiCampFinanceContributor', contributor)
        end
      end
    end

    exp_files.each do |year, files|
      next if year < start_year

      files.each do |file_name|
        file_url  = "https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/#{file_name}"
        file_path = "#{storehouse}store/#{file_name}"
        @scraper.download_file(file_url, file_path)

        @parser.parse_expenditure_file(file_path) do |data|
          data[:data_source_url] = file_url
          @keeper.save_data('MiCampFinanceExpenditure', data)
        end
      end
    end

    committe_url  = 'https://cfrsearch.nictusa.com/committees/spreadsheet?committeeType=*&office=*&district=*&party=*&status=active&isExactPhrase=off&useSpreadsheetFormat=on'
    committe_file = "#{storehouse}store/committees.txt"
    @scraper.download_file(committe_url, committe_file)
    @parser.parse_committee_file(committe_file) do |data|
      if data[:election_year].to_i >= start_year
        data[:data_source_url] = committe_url
        @keeper.save_data('MiCampFinanceCommittee', data)
      end
    end

    can_summ_url = 'https://miboecfr.nictusa.com/cfr/dumpall/micfrcansummary.txt.zip'
    can_summ_file = "#{storehouse}store/candidates.txt.zip"
    @scraper.download_file(can_summ_url, can_summ_file)
    @parser.parse_candidate_file(can_summ_file) do |data|
      if data[:statement_year].to_i >= start_year
        data[:data_source_url] = can_summ_url
        @keeper.save_data('MiCampFinanceCandidate', data)
      end
    end

    @keeper.flush
    @keeper.mark_deleted unless skip_delete
    @keeper.finish

    clear_file_storage
  rescue Exception => e
    cause_exc = e.cause || e
    unless cause_exc.is_a?(::Mysql2::Error) || cause_exc.is_a?(::ActiveRecord::ActiveRecordError)
      @keeper.flush rescue nil
    end
    raise e
  end

  private

  def clear_file_storage
    FileUtils.rm_r(Dir.glob("#{storehouse}store/*"))
  end
end
