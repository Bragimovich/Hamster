require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper

  BASE_URL = "https://www.fsa.usda.gov"
  MAIN_PAGE = "/news-room/efoia/electronic-reading-room/frequently-requested-information/payment-files-information/index"
  MAIN_FILE_NAME = "payment_0561"
  PROJECT_STORAGE_DIR = "/home/hamster/HarvestStorehouse/project_0561/store"


  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download(options)
    begin
      ## Clean the storage directory complete except the main file
      clean_storage_directory

      res, _ = @scraper.get_request("#{BASE_URL}#{MAIN_PAGE}")        
      save_file(res.body, MAIN_FILE_NAME)
      file_links = @parser.parse_main_page(BASE_URL,res.body)

      # Getting the year from options
      year = options[:year].to_i

      if file_links.has_key?(year)
        @logger.info "Downloading started for #{year}...".green

        ## Create year directory
        if !Dir.exist?("#{PROJECT_STORAGE_DIR}/#{year}")
          @logger.info "Creating directory for #{year} files..."
          Dir.mkdir("#{PROJECT_STORAGE_DIR}/#{year}")
        end

        ## We will download the links of selected year for storage purposes
        file_links[year].each_with_index{ | link, index | 
            @logger.info "--------------Starting #{year} -> Link# #{index} -----------------"
            file_name = "#{Digest::MD5.hexdigest(link)}.xlsx"
            link_storage_path = "#{PROJECT_STORAGE_DIR}/#{year}/#{file_name}"
            
            if File.exists?(link_storage_path)
              @logger.info "#{link} Already downloaded! Skipping...".green
            else
              @scraper.get_requested_file(link,link_storage_path)
              @logger.info "#{link} Done...".green
            end

            @logger.info "--------------Ending #{year} -> Link# #{index} -------------------"
        }
        @logger.info "Downloading ended for #{year}...".green
      else
        @logger.error "Invalid year given: #{year}".red
      end
    rescue StandardError => e
      @logger.error e.full_message
    end
  end

  def store(year)
    begin
      process_each_file(year)
    rescue Exception => e
      @logger.error e.full_message
    end
  end

  private

  def process_each_file(options)
    begin
      ## Parsing the main file for the links
      file_path = peon.copy_and_unzip_temp(file: MAIN_FILE_NAME)
      read_data = read_file(file_path)
      file_links = @parser.parse_main_page(BASE_URL,read_data)
      
      # Getting the year from options
      year = options[:year].to_i
              
      if file_links.has_key?(year) 
        @logger.info "Storing started for #{year}...".green

        ## Check for the downloaded files for the given year
        files = peek_directory("#{PROJECT_STORAGE_DIR}/#{year}")

        file_links[year].each_with_index{ | link, index |    
          link_file_name = "#{Digest::MD5.hexdigest(link)}.xlsx"
    
          if files.include? link_file_name
            @logger.info "Processing link: #{link}".yellow
            spreadsheet = @parser.get_spreadsheet("#{PROJECT_STORAGE_DIR}/#{year}/#{link_file_name}")
    
            spreadsheet.each_with_pagename do |name, sheet|
              sheet.each_row_streaming(pad_cells: true) do |rec_item|
                  rec = @parser.parse_record(rec_item)
                  ## For some reason, the 'start' param for each_row_streaming isn't working
                  ## so I had to add this logic to skip the first row
                  if rec[:state_fsa_code] != "State FSA Code" ## We are skipping the first row here
                    @keeper.store(rec.merge({"data_source_url": link}))
                  end
              end
            end
            @logger.info "Completed link: #{link}".green
          else
            @logger.info "WARNING -- NO FILE -- Skipping: #{link}".red
          end
        }
        @logger.info "Storing ended for #{year}...".green
        @keeper.finish
      else
        @logger.error "Invalid year given: #{year}".red
      end
    rescue StandardError => e
      @logger.error e.full_message
    end
  end

  def peek_directory(directory_path)
    files = File.directory?(directory_path) ? Dir.children(directory_path) : []
    files
  end

  def read_file(file_path)
    file = File.open(file_path).read
    file
  end

  def save_file(content, file_name)
    peon.put content: content, file: file_name
  end

  def clean_storage_directory
    @logger.info "Cleaning store...".yellow
    Dir.children(PROJECT_STORAGE_DIR).each { | item |
      item_path = "#{PROJECT_STORAGE_DIR}/#{item}"
      if File.file? item_path
        File.delete(item_path)
      elsif File.directory? item_path
        FileUtils.rm_rf(item_path)
      end
    }
  end

end
