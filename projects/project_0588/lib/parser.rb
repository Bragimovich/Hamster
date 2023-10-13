require_relative '../lib/manager'

class Parser < Hamster::Parser
  SUB_FOLDER = "njcourts"
  BASE_URL = "https://www.njcourts.gov"
  attr_accessor :run_id

  def initialize
    @scraper = Scraper.new
    # @peon = Peon.new(SUB_FOLDER)
    s              = Storage.new
    @_storehouse_  = "#{ENV['HOME']}/#{s.storage}/#{s.project}_#{Hamster.project_number}/"
    @_peon_        = Hamster::Harvester::Peon.new(storehouse)
  end

  def parse_data(data, run_id)
    @run_id = run_id
    {
      nj_sc_case_activities: nj_sc_case_activities_hash(data),
      nj_sc_case_additional_info: nj_sc_case_additional_info_hash(data),
      nj_sc_case_info: nj_sc_case_info_hash(data),
      nj_sc_case_party: nj_sc_case_party_hash(data),
      nj_sc_case_pdfs_on_aws: nj_sc_case_pdfs_on_aws_hash(data),
      nj_sc_case_relations_activity_pdf: nj_sc_case_relations_activity_pdf_hash(data)
    }
  end
  
  #nj_sc_case_activities table
  def nj_sc_case_activities_hash(data)
    case_activities_data = data.dig('case_activities').map{|ca| ca.merge({"court_id"=> 331, "case_id"=> data.dig('case_id'), "file"=> data.dig('file'), "touched_run_id"=> run_id, "run_id"=> run_id, "data_source_url"=> data.dig('file')})}
    case_activities_data.each do |data_hash|
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)    
      data_hash[:md5_hash] = md5_hash.hash
    end 
  end

  #nj_sc_case_additional_info table
  def nj_sc_case_additional_info_hash(data)
    data_hash = {}
    data_hash[:court_id] = 331
    data_hash[:case_id] = data.dig('case_id')
    data_hash[:lower_court_name] = data.dig('lower_court_name')
    data_hash[:lower_case_id] = data.dig('lower_case_id')
    data_hash[:data_source_url] = data.dig('file')
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:touched_run_id] = run_id
    data_hash[:run_id] = run_id
    data_hash
  end

  # nj_sc_case_info table
  def nj_sc_case_info_hash(data)
    data_hash = {}
    data_hash[:court_id] = 331
    data_hash[:case_id] = data.dig('case_id')
    data_hash[:case_name] = data.dig('case_name')
    data_hash[:case_filed_date] = data.dig('case_filed_date')
    data_hash[:case_description] = data.dig('case_description')
    data_hash[:status_as_of_date] = data.dig('status_as_of_date')
    data_hash[:lower_case_id] = data.dig('lower_case_id')
    data_hash[:data_source_url] = data.dig('file')
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:touched_run_id] = run_id
    data_hash[:run_id] = run_id
    data_hash
  end

  # nj_sc_case_party table
  def nj_sc_case_party_hash(data)
    return {} if data.dig('case_party_data').blank?
    case_party_data = data.dig('case_party_data').map{|ca| ca.merge({"court_id"=> 331, "case_id"=> data.dig('case_id'), "touched_run_id"=> run_id, "run_id"=> run_id, "data_source_url"=> data.dig('file')})}
    case_party_data.each do |data_hash|
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
    end
  end

  # nj_sc_case_pdfs_on_aws table
  def nj_sc_case_pdfs_on_aws_hash(data)
    data_hash = {}
    data_hash[:court_id] = 331
    data_hash[:case_id] = data.dig('case_id')
    data_hash[:aws_link] = data.dig('aws_link')
    data_hash[:source_link] = data.dig('file')
    data_hash[:source_type] = 'activity'
    data_hash[:data_source_url] = data.dig('file')
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:touched_run_id] = run_id
    data_hash[:run_id] = run_id
    data_hash
  end

  def nj_sc_case_relations_activity_pdf_hash(data)
    data_hash = {}
    data_hash[:case_activities_md5] = case_activity_md5_hash(data)
    data_hash[:case_pdf_on_aws_md5] = case_pdf_on_aws_md5_hash(data)
    data_hash[:data_source_url] = data.dig('file')
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:touched_run_id] = run_id
    data_hash[:run_id] = run_id
    data_hash
  end

  def case_activity_md5_hash(data)
    md5_hash = {
      court_id: 331,
      case_id: data.dig('case_id'),
      file: data.dig('file')
    }
    cols = %i[court_id case_id file]
    md5 = MD5Hash.new(:columns => cols)
    md5.generate(md5_hash)
    md5.hash
  end
  
  def case_pdf_on_aws_md5_hash(data)
    md5_hash = {
      court_id: 331,
      case_id: data.dig('case_id'),
      aws_link: data.dig('aws_link')
    }
    cols = %i[court_id case_id aws_link]
    md5 = MD5Hash.new(:columns => cols)
    md5.generate(md5_hash)
    md5.hash
  end

  def total_pages(response)
    html = Nokogiri.HTML(response.body)
    html.css('script')[6].text.split('total_pages')[1].match(/\d+/)[0]
  end

  def parse_html_data(response)
    html = Nokogiri.HTML(response.body)
    indx = 0
    case_c = html.css('p.h5')
    all_files  = peon.give_list(subfolder: SUB_FOLDER)
    case_c.each do |ci|
      case_info = ci.children.map{|t| t.text.squish}
      info = {}
      case_id = case_info[0]
      case_id = case_info[1].split(" ").first if case_info[0].blank?
      if all_files.include?("#{case_id.parameterize}.json.gz")
        p "Ignoring #{case_id}. Already downloaded"
        indx +=1
        next
      end
      info[:case_id] = case_id

      case_name = case_info[1]
      info[:case_name] = case_name.split(" (").first

      case_date_info = html.css('ul.list-unstyled')[indx].children.map{|d| d.text.squish}.compact_blank
      case_date_data = case_date_info.map{|d| d.split(":")}
      case_activities = case_date_data.map{|type, date| {activity_type: type, activity_date: date}}
      case_activities = case_activities.select{|c| c[:activity_date].present?}

      info[:case_filed_date] = case_activities.first[:activity_date].strip
      info[:status_as_of_date] = case_activities.last[:activity_type].strip
      info[:case_activities] = case_activities

      pdf_condition = ci.next_element.at('a')
      if pdf_condition.present?
        pdf_link = pdf_condition['href']
        case_detail = ci.next_element.next_element.text
      else
        pdf_link = ci.css('a').first&.get_attribute('href')
        case_detail = ci.next_element.text
      end
      info[:case_description] = case_detail

      if pdf_link.present?
        info[:file] = BASE_URL + pdf_link 
        pdf_path = @scraper.download_pdf(pdf_link)
        pdf_data = {}
        pdf_data = read_pdf(pdf_path, case_id) if pdf_path.present?
        begin
          info.merge!(pdf_data)
        rescue => e
          puts "Error #{e.message}"
        end
      end
      file_name = "#{case_id.parameterize}.json"
      peon.put content: info.to_json, file: "#{file_name}", subfolder: SUB_FOLDER
      indx +=1
    end
  end

  def read_pdf(path, case_id)
    pdf_file_data = {}
    page_number = 0
    begin
      pdf_reader = PDF::Reader.new(open(path))
      while true
        document = pdf_reader.pages[page_number].text.scan(/^.+/)
        index = document.index(document.select {|a| a.match(/^*COURT*/)}.first)
        page_number +=1
        break if index.present? || pdf_reader.page_count == page_number
      end
      return pdf_file_data if index.blank?

      pdf_file_data[:lower_court_name] = [document[index].strip, document[index+1].strip].join(", ")
      pdf_file_data[:lower_case_id] = document.select {|a| a.match(/^*DOCKET*/)}.first.to_s.split(".").last&.strip
      v_index = document.index(document.select{|a| a.match(/^*v.*/)}.first)
      i = -2
      pdf_file_data[:case_party_data] = []
      while true
        pdf_file_data[:case_party_data] << {
          party_name: document[v_index + i].strip,
          party_type: document[v_index + i + 1].strip
        }
        i+=3
        break if i==4
      end
      pdf_file_data[:aws_link] = @scraper.upload_file_aws(path, case_id)
      File.delete(path) if File.exist?(path)
      pdf_file_data
    rescue => e
      puts "An error occurred: #{e.message}"
    end
  end
end