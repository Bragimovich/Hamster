require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'
require 'roo'
class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    start_time = Time.new
    logger.debug "download started"
    html = scraper.download_main_page
    links = parser.page(html).excel_links 
    links.each do |link|
      scraper.download_and_save_file(link)
      sleep(5)
    end
    total_time = (Time.new - start_time)/3600
    logger.debug "download finished"
    logger.debug "total time #{total_time} hours"
    Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - #756 Downloaded, total time #{total_time}" , use: :slack)
  end

  def store
    start_time = Time.new
    logger.debug "db store process started"
    peon.list(subfolder: "files").each do |file|
      next unless file.match?(/.xlsx/)
      file_path = "#{scraper.files_path}/#{file}"
      data_source_url = File.read(file_path.gsub("xlsx","link").gsub("files","links"))&.strip
      logger.debug "file: #{file_path}"
      logger.debug "url: #{data_source_url}"
      file_info = keeper.file_info({data_source_url: data_source_url,data_source_file: file_path})
      next if file_info.status == 'processed'

      begin
        xlsx = Roo::Excelx.new(file_path)
        worksheet_name = xlsx.sheets.first
        worksheet = xlsx.sheet(worksheet_name)
        header = [];
        worksheet.each_row_streaming(pad_cells: true) do |row|
          next if row.flatten.empty?
          row_cells = row.map { |cell| cell&.value }
          if ["gsl","Quarter"].include?(row_cells[0]&.to_s)
            header = row_cells
          else
            if row_cells.size < header.size
              row_cells += [nil] * (header.size - row_cells.size)
            end
            row = Hash[[header, row_cells].transpose]
            row["data_source_url"] = data_source_url
            keeper.store(row)
          end
          
        end
        file_info.update(status: 'processed')
      rescue Zip::Error => e
        Hamster.logger.error e
        Hamster.logger.error file_path
        file_info.update(status: 'processed')
      end
    end
    keeper.finish
    scraper.cleanup
    logger.debug "db store process finished"
    total_time = (Time.new - start_time)/3600
    logger.debug "total time #{total_time} hours"
    Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - #756 Downloaded, total time #{total_time}" , use: :slack)
  end

  private

  attr_accessor :keeper, :parser, :scraper
end
