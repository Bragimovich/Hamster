# frozen_string_literal: true

COLUMNS = {
  root: %i[taxpayer_name taxpayer_address taxpayer_city_state_zip property_address property_type tax_year interest_date interest_pct amount interest fees penalties total_due property_url],
  site: %i[taxpayer_name taxpayer_address taxpayer_city_state_zip property_addresss property_type tax_year interest_date interest_percent amount interest fees penalties total_due property_url]
}

def make_md5(data, type=:root)
  all_values_str = ''
  COLUMNS[type].each do |key|
    if data[key].nil?
      all_values_str = all_values_str + data[key.to_s].to_s
    else
      all_values_str = all_values_str + data[key].to_s
    end
  end
  Digest::MD5.hexdigest all_values_str
end


class PimaTaxScraper < Hamster::Scraper
  ZIP_LIST     = %w[85601 85602 85611 85614 85619 85622 85629 85633 85658 85634 85637 85641 85321 85645 85653 85654 85701
                    85705 85704 85341 85707 85706 85709 85708 85711 85710 85713 85712 85715 85714 85716 85719 85718 85721
                    85723 85728 85730 85735 85737 85736 85739 85741 85743 85742 85745 85744 85747 85746 85749 85748 85750
                    85757 85755 85756]
  CSRF_TOKEN   = 'IC6bSZqRpwrvotPeAAguQ2cSWfrJWiiS'
  SCHEME       = 'https'
  HOST         = 'www.to.pima.gov'
  SEARCH_PATH  = 'propertySearch'
  TAX_PATH     = 'propertyInquiry'
  TAX_QUERY    = { 'stateCodeB' => 'None', 'stateCodeM' => 'None', 'stateCodeP' => 'None', 'stateCodePP' => 'None' }
  PIMA_PAGE    = Hamster.assemble_uri(scheme: SCHEME, host: HOST, path: SEARCH_PATH)
  PIMA_HEADERS =
    {
      Accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      Cookie:                    "csrftoken=#{CSRF_TOKEN}",
      Content_Type:              'application/x-www-form-urlencoded',
      Host:                      'www.to.pima.gov',
      Origin:                    'https://www.to.pima.gov',
      Referer:                   'https://www.to.pima.gov/propertySearch/',
      Upgrade_Insecure_Requests: '1'
    }
  BODY         = -> zip { "csrfmiddlewaretoken=IC6bSZqRpwrvotPeAAguQ2cSWfrJWiiS&form_zip=#{zip}" }
  
  def initialize
    super
    
    @proxy_filter            = ProxyFilter.new(duration: 1.hours, touches: 500)
    @state_dir               = "#{storehouse}/state"
    @fixed_zips_dir          = "#{@state_dir}/fixed_zips"
    @configure_file          = "#{@state_dir}/config.yml"
    @skipped_zips_file       = "#{@state_dir}/skipped_zips"
    @zips_processed_file     = "#{@state_dir}/zips_processed"
    @downloaded_records_file = "#{@state_dir}/downloaded_records"
    FileUtils.mkdir_p(@state_dir)
    FileUtils.mkdir_p(@fixed_zips_dir)
    
    @already_fixed = {}
    Dir.children(@fixed_zips_dir).sort.each do |zip|
      Dir.children("#{@fixed_zips_dir}/#{zip}").sort.each do |file|
        file                      = file.gsub(%r{\.gz}, '')
        @already_fixed[zip]       ||= {}
        @already_fixed[zip][file] = true
      end
    end
  end
  
  def gathering
    unless commands[:download].is_a?(TrueClass)
      parsed_properties_page = PimaTaxParser.new(properties_page_by(commands[:download]))
      p parsed_properties_page.has_records?
      
      return
    end
    
    FileUtils.rm_rf(@skipped_zips_file) unless commands[:save_prev]
    FileUtils.rm_rf(@zips_processed_file) unless commands[:save_prev]
    
    zips_processed = list_from_file(@zips_processed_file)
    
    zip_list.each do |zip|
      downloaded_records = list_from_file(@downloaded_records_file)
      retries            = 0
      
      parsed_properties_page = PimaTaxParser.new(properties_page_by(zip))
      
      if parsed_properties_page.has_records?
        all_zip_records = parsed_properties_page.records
      else
        
        if retries < 10
          retries += 1
          
          Hamster.countdown(rand(400..600), header: "Retrying ##{retries}. Trying to get real properties list of ZIP #{zip}...".red, label: 'Waiting before next try...')
          
          next
        else
          retries = 0
        end
        
        File.open(@skipped_zips_file, 'a') { |file| file.puts zip }
        log "#{zip} has no records", :red
        break
      end
      
      download_list = all_zip_records - downloaded_records
      
      loop do
        break if download_list.empty?
        
        current_record = download_list.pop
        
        Hamster.countdown(set_timer(:details), label: 'Waiting before a tax page downloading...')
        parsed_tax_page = PimaTaxParser.new(tax_page_from Hamster.assemble_uri(scheme: SCHEME, host: HOST, path: TAX_PATH, query: query(current_record)))
        
        log "#{zip} - #{current_record}", :yellow
        
        if parsed_tax_page.has_table?
          cut_document = <<~HTML
            <div id="propertyDetails">#{parsed_tax_page.property_details}</div>
            <div id="tblAcctBal">#{parsed_tax_page.table}</div>
          HTML
          
          peon.put content: cut_document, file: current_record, subfolder: zip
          
          FileUtils.mkdir_p("#{@fixed_zips_dir}/#{zip}/")
          FileUtils.touch("#{@fixed_zips_dir}/#{zip}/#{current_record}.gz")
        else
          log "#{current_record} didn't contain a table.", :red
        end
        
        downloaded_records << current_record
        File.write(@downloaded_records_file, downloaded_records.join("\n"))
      end

      Hamster.countdown(set_timer(:zips), label: 'Waiting before a properties list downloading...')
      
      zips_processed << zip
      File.write(@zips_processed_file, zips_processed.join("\n"))
      FileUtils.rm_rf(@downloaded_records_file)
    end
  end
  
  def storing
    db = PutInDb.new()
    peon.list.each do |zip|
      next if zip==".DS_Store" #todo
      documents = []
      md5_array = []
      peon.give_list(subfolder: zip).each do |file|
        puts "#{zip}: #{file}".yellow
        document = PimaTaxParser.new(peon.give(subfolder: zip, file: file))
        state_code = file.split('.')[0]
        document.parsed_page.each do |doc|
          doc['md5_hash'] = make_md5(doc, :site)
          doc['state_code'] = state_code
          md5_array.push(doc['md5_hash'])
          documents.push(doc)
        end
        if documents.length>100
          existed_md5 = db.exist(md5_array)
          db.update_touched_run_id(existed_md5)
          db.save(documents, existed_md5)
          md5_array = []
          documents = []
          db.reconnect
        end
      end
      existed_md5 = db.exist(md5_array)
      db.update_touched_run_id(existed_md5)
      db.save(documents, existed_md5)
      db.reconnect
    end
    db.update_delete_status
    db.put_done_for_run_id
  end
  
  def fix
    peon.list.each do |zip|
      next if zip==".DS_Store"
      peon.give_list(subfolder: zip).each do |file|
        file = file.gsub(%r{\.gz}, '')
        next if !@already_fixed[zip].nil? && @already_fixed[zip][file]
        
        parsed_tax_page = PimaTaxParser.new(tax_page_from Hamster.assemble_uri(scheme: SCHEME, host: HOST, path: TAX_PATH, query: query(file)))
        fixed_document  = <<~HTML
          <div id="propertyDetails">#{parsed_tax_page.property_details}</div>
          <div id="tblAcctBal">#{parsed_tax_page.table}</div>
        HTML
        
        peon.put content: fixed_document, file: file, subfolder: zip
        
        FileUtils.mkdir_p("#{@fixed_zips_dir}/#{zip}/")
        FileUtils.touch("#{@fixed_zips_dir}/#{zip}/#{file}.gz")
        
        Hamster.countdown(rand(1..2), label: 'Waiting before a tax page downloading...')
      end
    end
  end
  
  private
  
  def set_timer(key)
    config = {}
    3.times do
      if File.exist?(@configure_file)
        config = YAML.load_file(@configure_file)
        break
      end
      sleep 0.2
    end
    
    rand((config.is_a?(Hash) ? config.map { |key, value| [key.to_sym, value] }.to_h : config)[key])
  end
  
  def properties_page_by(zip)
    body = BODY[zip]
    resp = connect_to(PIMA_PAGE, req_body: body, headers: PIMA_HEADERS, proxy_filter: @proxy_filter, method: :post)
    if resp&.status == 200
      resp.body
    else
      ''
    end
  end
  
  def zip_list
    list      = ZipcodeData.select(:zip).where("county LIKE 'pima%'").to_a.map { |el| el[:zip].to_s }.concat(ZIP_LIST).uniq.sort
    processed = list_from_file(@zips_processed_file)
    list - processed
  end
  
  def tax_page_from(url)
    resp = connect_to(url, headers: PIMA_HEADERS, proxy_filter: @proxy_filter)
    if resp&.status == 200
      resp.body
    else
      ''
    end
  end
  
  def query(record)
    if record.size == 9
      code_b, code_m, code_p = record.match(%r{(.{3})(.{2})(.{4})}).to_a[1..-1]
      TAX_QUERY.merge 'stateCodeB' => code_b, 'stateCodeM' => code_m, 'stateCodeP' => code_p
    else
      TAX_QUERY.merge 'stateCodePP' => record
    end
  end

end
