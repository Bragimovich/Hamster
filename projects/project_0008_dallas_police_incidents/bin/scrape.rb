# frozen_string_literal: true

require_relative '../models/dallas_police_incidents_run'
require_relative '../models/dallas_police_incidents_update'

DATASET_ID = 'qv6i-rri7'
DOMAIN     = 'www.dallasopendata.com'
TOKEN      = 'BtnO9PupE2Ts6pg4JacdTe8JA'
META       = "https://#{DOMAIN}/api/views/metadata/v1/#{DATASET_ID}"

def scrape(options)
  begin
    s          = Storage.new
    storehouse = "#{ENV['HOME']}/#{s.storage}/#{s.project}_#{Hamster.project_number}/"
    break if File.exists?("#{storehouse}stop")
    
    DallasPoliceIncidentsRun.create!(status: 'processing') unless DallasPoliceIncidentsRun.last&.status == 'processing'
    current_run = DallasPoliceIncidentsRun.last
    
    soda          = -> action, method, column do
      case action
      when :send;
        "#{method}(#{column})"
      when :take;
        "#{method}_#{column}".to_sym
      else
        [action, method, column]
      end
    end
    time_at       = -> t, z { t.in_time_zone(z) }
    zone          = "Central America"
    dataset       = DallasPoliceIncidentsUpdate
    existing_rows = dataset.where(deleted: false)
    first_run     = existing_rows.empty?
    retries       = 0
    
    if options[:md5]
      # maybe it isn't necessary
      default_columns = %w[run_id data_source_url created_by created_at updated_at touched_run_id deleted md5_hash]
      client          = Mysql2::Client.new(Storage[host: :db01, db: :usa_raw].except(:adapter).merge(symbolize_keys: true))
      page_limit      = 1000
      number          = client.query("SELECT COUNT(*) count FROM #{dataset.table_name}").to_a.first[:count]
      
      sql             = <<~SQL
        SELECT id, #{default_columns.join(', ')} FROM #{dataset.table_name} ORDER BY id;
      SQL

      rows = client.query(sql).to_a.map! { |row| row[:md5_hash] = Digest::MD5.hexdigest row.except(:id).values.join('') }

      p rows.take(10)
      
      client.close
      
      return
    end
    
    unless first_run
      meta        = JSON(connect_to(META).body).to_h.with_indifferent_access
      last_update = time_at[Time.parse(meta[:dataUpdatedAt]), zone]
      last_run    = time_at[dataset.all.last.updated_at, zone]
      
      log "Last the source update was at #{last_update}", :yellow
      
      while (last_run > last_update) & options[:force].nil?
        meta        = JSON(connect_to(META).body).to_h.with_indifferent_access
        last_update = time_at[Time.parse(meta[:dataUpdatedAt]), zone]
        countdown(3600, header: 'Waiting for the source update...'.yellow, label: 'Next run in')
      end
    end
    
    results_count = 0
    
    begin
      results_count = SODA::Client
                        .new({ domain: DOMAIN, app_token: TOKEN })
                        .get(DATASET_ID, :$select => soda[:send, 'count', 'incidentnum'])
                        &.first[soda[:take, 'count', 'incidentnum']]
                        .to_i
    rescue Exception => e
      retries += 1
      
      report(to: 'Art Jarocki', message: "Project # 0008:\n#{e.full_message}", use: :both)
      
      sleep(60 - rand(30))
      retry if retries <= 10
      report(to: 'Art Jarocki', message: 'Retries count reached *10*.', use: :both)
      next
    ensure
      limit = 1_000
      pages = results_count / limit + 1
    end
    
    pages.times do |page|
      results = nil
      retries = 0
      
      begin
        results = SODA::Client
                    .new({ domain: DOMAIN, app_token: TOKEN, timeout: 30 })
                    .get(DATASET_ID, :$limit => limit, :$offset => page * limit, :$order => 'servnumid')
      rescue Exception => e
        retries += 1
        
        report(to: 'Art Jarocki', message: "Project # 0008:\n#{e.full_message}", use: :both)
        
        sleep(60 - rand(30))
        retry if retries <= 10
        report(to: 'Art Jarocki', message: 'Retries count reached *10*.', use: :both)
      end
      
      if results
        results.each_with_index do |incident, idx|
          print "\rCurrent ID: #{page * limit + idx + 1} | Total: #{results_count}".green
          
          incident.md5_hash = Digest::MD5.hexdigest incident.values.join('')
          data              = dataset.flail { |k| [k, incident[k]] }
          
          if first_run
            data[:compname_cleaned] = clean(data[:compname]) if data[:victimtype] == 'Individual'
            data[:ro1name_cleaned]  = clean(data[:ro1name])
            data[:ro2name_cleaned]  = clean(data[:ro2name])
            store(dataset, data, current_run)
            
            next
          end
          
          existing_row = nil
          retries      = 0
          
          begin
            existing_row = existing_rows.find_by(md5_hash: incident.md5_hash)
          rescue Exception => e
            retries += 1
            if retries <= 10
              Hamster.countdown(2**retries, header: "Error '#{e.message}' occurred while tried to get data from DB", label: 'Waiting before retry')
            end
            
            report(to: 'Art Jarocki', message: "Project # 0008:\n#{e.full_message}", use: :both)
            log e
          end
          
          if existing_row
            existing_row.update(touched_run_id: current_run.id)
          else
            data[:compname_cleaned] = clean(data[:compname]) if data[:victimtype] == 'Individual'
            data[:ro1name_cleaned]  = clean(data[:ro1name])
            data[:ro2name_cleaned]  = clean(data[:ro2name])
            store(dataset, data, current_run)
          end
        end
        
        puts
      end
    end
    
    retries = 0
    
    begin
      dataset.where(deleted: false).where.not(touched_run_id: current_run.id).update_all(deleted: true)
      
      message = "Project # 0008: count stored rows doesn't match received count."
      report(to: 'Art Jarocki', message: message, use: :both)
      raise message unless results_count == dataset.where(deleted: false).size
      
      DallasPoliceIncidentsRun.find_by(id: current_run.id).update(status: 'done')
    rescue Exception => e
      retries += 1
      if retries <= 10
        Hamster.countdown(3, header: "Error '#{e.message}' occurred while tried to put data to DB", label: 'Waiting before retry')
      end
      
      report(to: 'Art Jarocki', message: "Project # 0008:\n#{e.full_message}", use: :both)
      log e
    end
    
    report(to: 'Art Jarocki', message: 'Project # 0008 done a round.', use: :telegram)
  end while options[:force].nil?
  
  unless options[:force].nil?
    report(to: 'Art Jarocki', message: 'Project # 0008 was started in force mode and need to rerun in casual mode', use: :both)
  else
    report(to: 'Art Jarocki', message: 'Project # 0008 stopped scrape.', use: :telegram)
  end
end

def clean(name)
  return nil if name.nil?
  
  name.gsub(%r{^([^,]+)\s*,\s*([^,]+)\s*(?>,\s*(.+)\s*)?$}) do
    lastname, firstname, middlename = $1, $2, $3
    
    # multiple words at a last name
    lastname = lastname.split(' ').map { |w| w.split('-').map(&:capitalize).join('-') }.join(' ')
    # irish and scott names
    lastname  = lastname.gsub(%r{\b(mc\s*)(\w{3,})}i) { "#{$1.capitalize.strip}#{$2.capitalize.strip}" }
    lastname  = lastname.gsub(%r{\b(o\b[']?\s*)(\w{3,})}i) { "#{$1.capitalize.strip}'#{$2.capitalize.strip}".squeeze("'") }
    firstname = firstname.gsub(%r{\b(\w+)\b}) { |word| word.size == 1 ? "#{word}." : word.capitalize }
    
    if middlename
      middlename = middlename.gsub(%r{\b(\w+)\b}) do |word|
        word.size == 1 ? "#{word}.".capitalize : word.capitalize
      end unless middlename.match?(%r{\b(i{1,3}|iv|v|vi{1,3}|ix|x)\b}i)
      middlename = middlename.gsub(/\s+/, ' ')
    end
    
    result = "#{firstname} #{middlename} #{lastname}"
    result = "#{result.gsub(/\b((?>i{1,3}|iv|v|vi{1,3}|ix|x)(?!\.)|[js]r\.?)\b/i, '')} #{Regexp.last_match}"
    result = result.gsub(/\b([js]r)$/i, '\1.')
    result.squeeze(' ').squeeze("'").squeeze('.').strip
  end
end

def store(dataset, data, current_run)
  data[:run_id]         = current_run.id
  data[:touched_run_id] = current_run.id
  
  retries = 0
  
  begin
    dataset.store(data)
  rescue Exception => e
    sleep 2**retries
    retries += 1
    if retries <= 10
      Hamster.countdown(3, header: "Error '#{e.message}' occurred while tried to put data to DB", label: 'Waiting before retry')
    end
    
    report(to: 'Art Jarocki', message: "Project # 0008:\n#{e.full_message}", use: :both)
    log e
  end
end
