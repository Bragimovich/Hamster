require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require 'pry'

class Manager < Hamster::Scraper
  BASE_URL = "http://rijrs.courts.ri.gov/rijrs"
  SUB_FOLDER = 'lawyerStatus'

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @dir_path = @_storehouse_ + 'filename_link.csv'
    @files_to_link = {}
    @outerfilename_to_link = {}
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      table.map{ |x| @files_to_link[x[0]] = x[1] }
      outer_pages = table.select{|x| x[0].include?("outer_page_")}
      outer_pages.map{|x| @outerfilename_to_link[x[0]]= x[1]}
    end
  end
    
  def download
    ('a'..'z').to_a.each do |char|
      outer_link = "http://rijrs.courts.ri.gov/rijrs/searchAttorney.do?subactionId=2&lastName=#{char}%25&firstName=&middleName="
      outer_file_name = "outer_page_" + Digest::MD5.hexdigest(outer_link) + '.gz'
      outer_page_response , status = @scraper.download_main_page_with_form(outer_link)
      next if status != 200
      
      all_rows_in_table = @parser.get_all_records(outer_page_response.body) 
      all_records = @parser.parse_rows(all_rows_in_table)

      all_records.each do |record|
        inner_page_url = BASE_URL + record['href'][1..-1]
        inner_file_name = Digest::MD5.hexdigest(inner_page_url) + '.gz'
        inner_page_response , status = @scraper.download_inner_page(inner_page_url)
        next if status != 200
        save_file(inner_page_response, inner_file_name)
        save_csv(inner_file_name, inner_page_url)
      end

      # saving outer page
      save_file(outer_page_response, outer_file_name)
      save_csv(outer_file_name, outer_link)
    end
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  def process_each_file
    @outerfilename_to_link.each do |file_name|
      file_content = peon.give(subfolder: SUB_FOLDER, file: file_name[0])
      puts "Parsing outer_page #{file_name[1]}".yellow
      all_rows_in_table = @parser.get_all_records(file_content)
      @parser.parse_rows(all_rows_in_table).each do |par_hash|
        inner_page_url = BASE_URL + par_hash['href'][1..-1]
        puts "Processing Inner link #{inner_page_url}".blue
        file_name = Digest::MD5.hexdigest(inner_page_url) + '.gz'
        file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
        par_hash2 = @parser.parse_inner_page(file_content)
        result = par_hash2.merge(par_hash)
        # removing href key
        result.delete('href')
        @keeper.store(result)
      end
    end
    @keeper.finish
  end

  private

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def save_csv(file_name,link)
    rows = [[file_name , link]]
    File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
  end
end