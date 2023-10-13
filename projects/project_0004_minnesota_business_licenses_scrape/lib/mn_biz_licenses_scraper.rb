# frozen_string_literal: true

require_relative 'mn_biz_licenses_parser'
require_relative '../models/minnesota_business_license_business_base_data'
require_relative '../models/minnesota_business_license_business_address'
require_relative '../models/minnesota_business_license_trademark_base_data'
require_relative '../models/minnesota_business_license_trademark_address'
require_relative '../models/minnesota_business_license_run'

class MNBizLicensesScraper < Hamster::Harvester
  LETTERS = ('0'..'9').to_a + ('a'..'z').to_a
  STOCK   = "store"
  TRASH   = "trash"
  HEADERS = {
    accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    accept_language:           'en-US,en;q=0.9',
    cache_control:             'max-age=0',
    connection:                'keep-alive',
    host:                      'mblsportal.sos.state.mn.us',
    sec_fetch_dest:            'document',
    sec_fetch_mode:            'navigate',
    sec_fetch_site:            'same-origin',
    sec_fetch_user:            '?1',
    upgrade_insecure_requests: '1'
  }
  
  attr_writer :silence, :save_to
  
  def initialize
    super
    @details      = {
      biz: {
        base: MinnesotaBusinessLicenseBusinessBaseData,
        addr: MinnesotaBusinessLicenseBusinessAddress
      },
      tm:  {
        base: MinnesotaBusinessLicenseTrademarkBaseData,
        addr: MinnesotaBusinessLicenseTrademarkAddress
      }
    }
    @runs         = MinnesotaBusinessLicenseRun
    @silence      = false
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    
    FileUtils.mkdir_p(storehouse)
    FileUtils.mkdir_p(stock_path)
    FileUtils.mkdir_p(trash_path)
    
    @configure_file = "#{storehouse}/timer.yml"
  end
  
  def download(id)
    if id.is_a? String
      download_details(id)
      return
    end
    
    search_dir = -> (file = '') { "#{storehouse}searches/#{file}" }
    source     = MNBizLicensesParser.new
    companies  = 0
    round      = 0
    searches   = []
    done       = []
    
    if Dir.exist?(search_dir[])
      companies = File.read(search_dir['companies']).to_i if File.exist?(search_dir['companies'])
      round     = File.read(search_dir['round']).to_i if File.exist?(search_dir['round'])
      searches  = File.read(search_dir['processing']).strip.split("\n").uniq if File.exist?(search_dir['processing'])
      done      = File.read(search_dir['done']).strip.split("\n").uniq if File.exist?(search_dir['done'])
    end
    
    FileUtils.mkdir_p(search_dir[])
    
    loop do
      break if File.exist?("#{storehouse}stop")
      @runs.create!(status: 'processing') unless @runs.last&.status == 'processing'
      @current_run = @runs.last
      
      loop do
        break if File.exist?("#{storehouse}stop")
        
        begin
          search = searches.shuffle(random: Random.new).shift
        end while done.include? search
        
        LETTERS.each do |letter|
          # next if search && search.size > 7
          #
          break if File.exist?("#{storehouse}stop")
          
          @current_search        = round.zero? ? letter : search + letter
          source.business_search = @current_search
          response               = connect_to(url: Hamster.assemble_uri(source.business_search), headers: HEADERS)
          
          next if response.nil?
          
          source.document = response.body
          
          ap source.alert unless @silence
          
          if /500 results/.match?(source.alert)
            ap alert: 'over 500 results' unless @silence
            searches << @current_search
            next
          end
          
          next if source.table_empty?
          
          @list_size = source.table_size
          
          source.company_ids.each_with_index do |company_id, index|
            break if File.exist?("#{storehouse}stop")
            
            download_details(company_id, index: index)
            companies += 1
            File.write(search_dir['companies'], companies)
            
            Hamster.countdown(set_timer, label: 'Pause before next page download')
          end
          
          File.open(search_dir['done'], 'a') { |f| f.puts(@current_search) }
          File.write(search_dir['processing'], searches.join("\n"))
        end
        
        break if searches.empty?
        round += 1
        File.write(search_dir['round'], round)
      end
      
      break if File.exist?("#{storehouse}stop")
      
      puts 'Waiting when store_companies method done...'
      until Dir.empty?("#{storehouse}store/")
        break if File.exist?("#{storehouse}stop")
        sleep(1)
      end
      @runs.find_by(id: @current_run.id).update(status: 'done')
      Hamster.report(to: 'Art Jarocki', message: 'Project #0004 (MN Biz Licenses): downloading done a round.', use: :telegram)
    end
    
    FileUtils.rm_rf(search_dir[])
  end
  
  def store_companies(id)
    loop do
      break if File.exist?("#{storehouse}stop")
      @current_run  = @runs.last
      download_list = []
      started_at    = Time.now
      
      @list_size    = peon.give_list.size
      source        = MNBizLicensesParser.new
      store_company = -> (file, index = nil) do
        source.search_details = file.split('.').first
        company               = store(source, peon.give(file: file))
        
        unless commands[:silence]
          reporting_details(source.company_url, index)
          pp company
        end
        
        peon.move(file: file)
      end
      
      if id.is_a?(String)
        store_company["#{id}.html.gz"]
      else
        download_list = peon.give_list
        download_list.each_with_index do |file, index|
          break if File.exist?("#{storehouse}stop")
          store_company[file, index]
        end
        
        break if File.exist?("#{storehouse}stop")
        
        if @current_run.id > 1
          @details[:biz][:base].where(deleted: false).where.not(touched_run_id: @current_run.id).each { |row| row.update(deleted: true) }
          @details[:biz][:addr].where(deleted: false).where.not(touched_run_id: @current_run.id).each { |row| row.update(deleted: true) }
          @details[:tm][:base].where(deleted: false).where.not(touched_run_id: @current_run.id).each { |row| row.update(deleted: true) }
          @details[:tm][:addr].where(deleted: false).where.not(touched_run_id: @current_run.id).each { |row| row.update(deleted: true) }
        end
      end
      
      break if File.exist?("#{storehouse}stop")
      
      Hamster.report(to: 'Art Jarocki', message: 'Project #0004 (MN Biz Licenses): files stored once again.', use: :telegram) unless download_list.size.zero?
      Hamster.countdown((started_at.to_i + 1.day.to_i) - Time.now.to_i, label: "Waiting for next run...", store: storehouse)
    end
  end
  
  private
  
  def set_timer
    period = ''
    3.times do
      if File.exist?(@configure_file)
        period = YAML.load_file(@configure_file)
        break
      end
      sleep 0.2
    end
    
    rand(period)
  end
  
  def download_details(company_id, index: nil)
    source                = MNBizLicensesParser.new
    source.search_details = company_id
    company_url           = source.company_url
    response              = connect_to(url: company_url, headers: HEADERS)
    body                  = response&.body.gsub(/\s+/m, ' ')
    
    peon.put(file: "#{company_id}.html", content: body)
    
    unless commands[:silence]
      reporting_details(company_url, index)
    end
  end
  
  def stock_path
    if commands[:temp]
      "#{Dir.pwd}/projects/project_0004_minnesota_business_licenses_scrape/html_storage"
    else
      "#{storehouse}#{STOCK}/"
    end
  end
  
  def trash_path
    "#{storehouse}#{TRASH}/"
  end
  
  def store(source, content)
    puts source_url = Hamster.assemble_uri(source.search_details)
    source.document = content
    
    additional_columns = {
      company_id:       source.company_id,
      run_id:           @current_run.id,
      data_source_url:  source_url,
      created_by:       'Art Jarocki',
      last_scrape_date: Time.now.to_s
    }
    
    source.gather_company_info
    
    source.company_details[:md5_hash] = Digest::MD5.hexdigest source.company_details.values.join('')
    
    company_details = source.company_details.merge(additional_columns)
    company_address = source.company_address
    
    existing_rows        = {}
    detail_type          = company_details[:mark_type] ? :tm : :biz
    base_data            = @details[detail_type][:base].flail { |k| [k, company_details[k]] }
    existing_rows[:base] = @details[detail_type][:base].where(deleted: false)
    existing_rows[:addr] = @details[detail_type][:addr].where(deleted: false)
    first_run            = @current_run.id == 1
    
    company_address = company_address.map do |type, addresses|
      addresses = addresses.map do |address|
        address[:md5_hash] = Digest::MD5.hexdigest address.values.join('')
        @details[detail_type][:addr].flail do |column|
          value = address.merge(address_type: type.to_s).merge(additional_columns)[column]
          value = '' if value.nil?
          [column, value]
        end
      end
      [type, addresses]
    end.to_h
    
    if first_run
      base_data[:touched_run_id] = @current_run.id
      @details[detail_type][:base].store(base_data)
      
      company_address.values.each do |addresses|
        addresses.each do |address|
          address[:touched_run_id] = @current_run.id
          @details[detail_type][:addr].store(address)
        end
      end
      
      return { details: company_details, address: company_address }
    end
    
    existing_row        = {}
    existing_row[:base] = existing_rows[:base].find_by(company_id: company_details[:company_id])
    store_current_row   = -> table_type, data do
      @details[detail_type][table_type].store(data)
    rescue Exception => e
      Hamster.report(to: 'Art Jarocki', message: "Project #0004[store to DB] (MN Biz Licenses):\n#{e.full_message}", use: :both)
      log e
    end
    
    if existing_row[:base] && existing_row[:base][:md5_hash] == company_details[:md5_hash]
      existing_row[:base].update(touched_run_id: @current_run.id)
    else
      existing_row[:base].update(deleted: true) if existing_row[:base]
      base_data[:run_id]         = @current_run.id
      base_data[:touched_run_id] = @current_run.id
      store_current_row[:base, base_data]
    end
    
    company_address.each do |type, addresses|
      addresses.each_with_index do |address, idx|
        existing_row[:addr] = existing_rows[:addr].find_by(company_id: address[:company_id])
        
        if existing_row[:addr] && existing_row[:addr][:md5_hash] == address[:md5_hash]
          existing_row[:addr].update(touched_run_id: @current_run.id)
        else
          existing_row[:addr].update(deleted: true) if existing_row[:addr]
          address[:run_id]         = @current_run.id
          address[:touched_run_id] = @current_run.id
          store_current_row[:addr, address]
        end
      end
    end
    
    { details: company_details, address: company_address }
  end
  
  def connect_to(url:, headers: {}, proxy: nil)
    begin
      response = Hamster.connect_to url, headers: headers, proxy: proxy, proxy_filter: @proxy_filter, open_timeout: 2
      
      reporting_request(response) if response
      
      if [301, 302].include?(response&.status)
        pause = 100 + rand(500)
        Hamster.countdown(pause, label: 'Restart connection after ')
      end
    end until response&.status == 200
    
    response
  end
  
  def reporting_request(response)
    unless @silence
      puts '=================================='.yellow
      print 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      puts response.status == 200 ? status.greenish : status.red
      puts '=================================='.yellow
    end
  end
  
  def reporting_details(url, index = nil)
    unless @silence
      unless @current_search.nil?
        print 'Current search: '.indent(1, "\t").green
        puts @current_search.upcase.yellowish
        puts '=================================='.yellow
      end
      unless index.nil?
        print "Companies: ".indent(1, "\t").green
        puts "#{index + 1} / #{@list_size}".cyanish
        puts '=================================='.yellow
      end
      
      puts url.blue
    end
  end
end
