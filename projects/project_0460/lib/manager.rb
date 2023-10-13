require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @sub_folder = "RunId_#{keeper.run_id}"
    @already_downloaded_files = peon.give_list(subfolder: @sub_folder)
  end

  def download(retries = 10)
    begin
      scraper = Scraper.new
      header_token = scraper.token_generator
      attorney_reg =  get_max_downloaded_attr_reg
      empty_records = 0
      while empty_records < 2000
        file_data = scraper.scraper(attorney_reg, header_token)
        if file_data != "No Data"
          save_file(file_data, "Lawyer-#{attorney_reg}", @sub_folder)
          attorney_reg += 1
          empty_records = 0
        else
          attorney_reg += 1
          empty_records += 1
        end
      end
    rescue
      raise if retries <= 1
      download(retries -1)
    end
    keeper.finish_download
    store
  end

  def store
    data_array = []
    md5_array = []
    break_counter = 0
    peon.give_list(subfolder: @sub_folder).each do |file_name|
      file_content = peon.give(subfolder: @sub_folder, file:file_name)
      begin 
        data_hash = parser.parser(file_content, keeper.run_id)
      rescue Exception => e
        if (e.full_message.include? "JSON::ParserError")
          next
        else
          break_counter += 1
          raise e.full_message if break_counter > 4
          report(to: 'Tauseeq Tufail', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
          next
        end
      end
      md5_array << data_hash[:md5_hash]
      data_array << data_hash
      if (data_array.count == 10000)
        keeper.update_touched_run_id(md5_array)
        keeper.save_record(data_array)
        data_array = []
        md5_array = []
      end
    end

    if (data_array.count >= 1)
      keeper.update_touched_run_id(md5_array)
      keeper.save_record(data_array)
    end

    if (keeper.download_status == "finish")
      keeper.mark_deleted
      keeper.finish
    end
  end

  private

  attr_accessor :keeper, :parser

  def get_max_downloaded_attr_reg
    @already_downloaded_files.map{|s| s.scan(/\d+/)[0].to_i}.max || 0
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end
end
