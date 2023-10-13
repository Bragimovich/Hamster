require 'roo-xls'
require_relative 'parser'
require_relative 'keeper'
require_relative 'scraper'
require_relative 'constants'

class Manager < Hamster::Scraper

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    # Save the main downloads page
    res, _ = @scraper.get_request(DOWNLOADS_PAGE_URL)        
    save_file(res.body, MAIN_FILE_NAME)

    # Save all the section by section
    SUB_DIRECTORIES.each{ |sub_dir|

      sub_directory_path = "#{PROJECT_STORAGE_DIR}/#{sub_dir[:table_name]}"

      if !Dir.exist?(sub_directory_path)
        @logger.info "Creating directory for #{sub_dir[:table_name]} files..."
        Dir.mkdir(sub_directory_path)
      else
        @logger.info "#{sub_directory_path} directory already exists!"
      end

      @logger.info "Starting Download for: #{sub_dir[:title]}----------------------"
      section_urls = @parser.get_section_urls(res.body, sub_dir[:title])
      section_urls.each{|url| 
        if url == ""
          ## This is only for Hope Eligible 2009 link, as there is no link for it in the main page
          @logger.info "Empty Url for #{sub_dir[:title]}"
        else
          url_obj = get_url_hash(url)
          if url.include? "https"
            secure_url =  url
          else
            secure_url =  url.sub('http','https')
          end 
          @logger.info "Downloading #{secure_url} ..."
          file_path = "#{sub_directory_path}/#{url_obj[:hash]}.#{url_obj[:extension]}"
          @scraper.get_requested_file(secure_url, file_path)
        end
      }
      @logger.info "Ending Download for: #{sub_dir[:title]}------------------------"
    }
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      @logger.error e.full_message
    end
  end

  private

  def process_each_file
    # We will insert the first record of the state to the general_info
    @keeper.sync_general_info_table

    file_path = peon.copy_and_unzip_temp(file: MAIN_FILE_NAME)  
    raw_file_data = read_file(file_path)
    
    @logger.info "Processing started..."

    process_section(raw_file_data, "ga_enrollment_by_grade", URLS_TO_SKIP["ga_enrollment_by_grade"])
    process_section(raw_file_data, "ga_enrollment_by_subgroup", URLS_TO_SKIP["ga_enrollment_by_subgroup"])
    process_section(raw_file_data, "ga_assessment_eoc_by_grade", URLS_TO_SKIP["ga_assessment_eoc_by_grade"])
    process_section(raw_file_data, "ga_assessment_eoc_by_subgroup", URLS_TO_SKIP["ga_assessment_eoc_by_subgroup"])
    process_section(raw_file_data, "ga_assessment_eog_by_grade", URLS_TO_SKIP["ga_assessment_eog_by_grade"])
    process_section(raw_file_data, "ga_assessment_eog_by_subgroup", URLS_TO_SKIP["ga_assessment_eog_by_subgroup"])
    process_section(raw_file_data, "ga_graduation_4_year_cohort", URLS_TO_SKIP["ga_graduation_4_year_cohort"])
    process_section(raw_file_data, "ga_graduation_5_year_cohort", URLS_TO_SKIP["ga_graduation_5_year_cohort"])
    process_section(raw_file_data, "ga_salaries_benefits", URLS_TO_SKIP["ga_salaries_benefits"])
    process_section(raw_file_data, "ga_revenue_expenditure", URLS_TO_SKIP["ga_revenue_expenditure"])
    process_section(raw_file_data, "ga_graduation_hope", URLS_TO_SKIP["ga_graduation_hope"])
    
    @logger.info "Processing ended..."

    @keeper.finish
  end

  def process_section(main_file_data, section_name, urls_to_skip)
    @logger.info "Processing for #{section_name} STARTED..."
    section_details = get_section(main_file_data, section_name)

    section_details[:links].each{|url|
      url_obj = get_url_hash(url)
      if urls_to_skip.include? url or url.empty?
        @logger.info "#{url} SKIPPED!"
      elsif url_obj
        @logger.info "#{url} STARTING!"
        file_path = "#{section_details[:path]}/#{url_obj[:hash]}.#{url_obj[:extension]}" 
        if File.exist?(file_path)
          is_3sheet_file = is_3sheet_xls(file_path, url_obj[:extension])
          if is_3sheet_file
            # Working in reverse order in case, we might have a school which might have undocumented district
            file_sheets = [
              get_headers_and_records(file_path, url_obj[:extension], 2), # State Sheet
              get_headers_and_records(file_path, url_obj[:extension], 1), # District Sheet
              get_headers_and_records(file_path, url_obj[:extension], 0), # School Sheet
            ]
          else
            file_sheets = [get_headers_and_records(file_path, url_obj[:extension], 0)]
          end
          file_sheets.each{ |sheet|
            sheet[:records].each{ |record|
              # @logger.info("PROCESSING #{record}")
              ids_for_general_info = @parser.get_ids_for_general_info(section_name, record, sheet[:headers], url)

              # In case the record is missing the number, we will skip the record 
              if ids_for_general_info[:type]  == 'District' and [nil, ''].include? ids_for_general_info[:district_number]
                @logger.info "Skipping #{record} ".yellow
                next
              elsif ids_for_general_info[:type]  == 'School' and [nil, ''].include? ids_for_general_info[:school_number]
                @logger.info "Skipping #{record} ".yellow
                next
              end   
              
              if ids_for_general_info[:type]  == 'State'
                state_general_id = @keeper.get_general_info_id(ids_for_general_info)
                # @logger.info "General ID found for state #{record}".green
                parsed_item = @parser.parse_item(section_name, record, state_general_id, url, sheet[:headers])
                store_item(section_name, parsed_item)
              else
                # We need to ensure that if the record is a school, then it's district exists
                # We can also use this when the record is a district, and we need to insert it
                general_info_for_district = @parser.get_general_info_from(section_name, record, "District", url, sheet[:headers])
                district_general_id = @keeper.get_general_info_id(ids_for_general_info.merge({type: "District"}))

                # We check that if the district_general_id exists, we can safely check for school
                if !district_general_id
                  @logger.info("Inserting new district and retreiving id")
                  @keeper.store_ga_district(general_info_for_district)                    
                  district_general_id = @keeper.get_general_info_id(ids_for_general_info.merge({type: "District"}))
                end

                if ids_for_general_info[:type]  == 'District'
                  # We already have the district_general_id , so will use it.
                  parsed_item = @parser.parse_item(section_name, record, district_general_id, url, sheet[:headers])
                  store_item(section_name, parsed_item)
                elsif ids_for_general_info[:type]  == 'School'
                  general_info_for_school = @parser.get_general_info_from(section_name, record, "School", url, sheet[:headers])
                  school_general_id = @keeper.get_general_info_id(ids_for_general_info)

                  if !school_general_id
                    @logger.info("Inserting new school and retreiving id")
                    school_info = general_info_for_school.merge({ district_id: district_general_id })
                    @keeper.store_ga_school(school_info, district_general_id, true)
                    school_general_id = @keeper.get_general_info_id(ids_for_general_info)
                  else
                    parsed_item = @parser.parse_item(section_name, record, school_general_id, url, sheet[:headers])
                    store_item(section_name, parsed_item)
                  end                  
                end                
              end
            } 
          }         
        else
          @logger.info "#{file_path} does not exist!".red
        end
      end
    }
    @logger.info "Processing for #{section_name} ENDED..."
  end

  def store_item(section_name, item)
    if section_name == "ga_enrollment_by_grade"
      @keeper.store_ga_enrollment_by_grade(item)
    elsif section_name == "ga_enrollment_by_subgroup" ## In this case we have a list of record instead of record
      item.each{ |rec|
        @keeper.store_ga_enrollment_by_subgroup(rec)
      }
    elsif section_name == "ga_assessment_eoc_by_grade"
      @keeper.store_ga_assessment_eoc_by_grade(item)
    elsif section_name == "ga_assessment_eoc_by_subgroup"
      @keeper.store_ga_assessment_eoc_by_subgroup(item)
    elsif section_name == "ga_assessment_eog_by_grade"
      @keeper.store_ga_assessment_eog_by_grade(item)
    elsif section_name == "ga_assessment_eog_by_subgroup"
      @keeper.store_ga_assessment_eog_by_subgroup(item)
    elsif section_name == "ga_graduation_4_year_cohort" ## In this case we have a list of record instead of record
      item.each{ |rec|
        @keeper.store_ga_graduation_4_year_cohort(rec)
      }
    elsif section_name == "ga_graduation_5_year_cohort" ## In this case we have a list of record instead of record
      item.each{ |rec|
        @keeper.store_ga_graduation_5_year_cohort(rec)
      }
    elsif section_name == "ga_salaries_benefits"
      @keeper.store_ga_salaries_benefits(item)
    elsif section_name == "ga_revenue_expenditure"
      @keeper.store_ga_revenue_expenditure(item)
    elsif section_name == "ga_graduation_hope"
      @keeper.store_ga_graduation_hope(item)
    else
      @logger.info "Not storing ".red
    end 
  end

  def get_section(data, section_name)
    section = SUB_DIRECTORIES.find{|item| item[:table_name] == section_name}
    
    if section
      sub_directory_path = "#{PROJECT_STORAGE_DIR}/#{section[:table_name]}"
      if !Dir.exist?(sub_directory_path)
        @logger.info "#{sub_directory_path} directory does not exists!".red
      else
        @logger.info "Processing #{section[:title]} ...".green
        section_urls = @parser.get_section_urls(data, section[:title])
        return {
          "path": sub_directory_path,
          "links": section_urls
        }
      end
    else
      @logger.info "#{section_name} is not a valid section name!".red
    end
  end

  def get_url_hash(url)
    if url == ""
      @logger.info "Empty URL".yellow
    else
      file_extension = url.split(".")
      file_ext = ["csv","xls","xlsx"].include?(file_extension[-1]) ? file_extension[-1] : "csv"
      {
        "hash": Digest::MD5.hexdigest(url),
        "extension": file_ext
      }
    end
  end

  def is_3sheet_xls(file_path, extension)
    if "xls" == extension
      file = Spreadsheet.open(file_path)
      sheets = file.worksheets.length
      return sheets == 3
    elsif "xlsx" == extension
      file = Roo::Excelx.new(file_path)
      sheets = file.sheets.length
      return sheets == 3
    else
      return false
    end
  end

  def get_headers_and_records(file_path, extension , sheet_index)
    if extension == "csv"
      return csv_parser(file_path, 1)
    elsif ["xls","xlsx"].include?(extension)
      return xls_parser(file_path, extension, sheet_index)
    else
      @logger.info "Bad extension".red
    end
  end

  def xls_parser(file_path, extension, number)
    if "xls" == extension
      file = Spreadsheet.open(file_path)
      rows = file.worksheets[number].rows
   
      if rows.length == 0
        @logger.info "Empty sheet".yellow
        return {
          headers: {},
          records: []
        }
      else
        headers = rows[0].map{|column | column}
        return {
          headers: headers,
          records: rows[1..].select{ |row| !row.compact.empty? }.map{|row|
            row.map{|cell| cell.is_a?(Spreadsheet::Formula) ? cell.value : cell}
          }
        }
      end

    elsif "xlsx" == extension
      file = Roo::Excelx.new(file_path)
      sheets = file.sheets
      rows = []

      file.sheet(sheets[number]).each_row_streaming do |row|
        temp_rec=[]
        row.each do |cell|
          temp_rec << cell.value
        end
        rows << temp_rec
      end

      headers = rows[0].map{|column | column}
      return {
        headers: headers,
        records: rows[1..].select{ |row| !row.compact.empty? }
      }
    else 
      @logger.info "Cannot parse given file!"
    end
  end

  def csv_parser(file_name,lines_to_skip)
    lines = File.open(file_name, "r").readlines

    raw_header_row = lines[0]
    enc_header_row = raw_header_row.encode("UTF-8", invalid: :replace, replace: "")
    header_row = CSV.parse(enc_header_row.strip.gsub("=",""), quote_char: '"')
    
    lines = lines[lines_to_skip..-1]
    
    list = []
    lines.each_with_index do |line, index|    
      if line.length > 10 ## Is this wise to skip, incomplete rows like this?
        line = line.encode("UTF-8", invalid: :replace, replace: "")
        line = line.gsub(/"""/,'"')
        
        row = CSV.parse(line.strip.gsub("=",""), quote_char: '"', skip_lines: /^(0")+/)
        list << row[0]
      end
    end
    return {
      headers: header_row[0],
      records: list.select{ |row| row != nil }
    }
  end


  def read_file(file_path)
    file = File.open(file_path).read
    file
  end

  def save_file(content, file_name)
    peon.put content: content, file: file_name
  end

end