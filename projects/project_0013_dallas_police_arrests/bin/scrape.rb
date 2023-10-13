# frozen_string_literal: true

require_relative '../models/dallas_police_arrests_run'
require_relative '../models/dallas_police_arrests_update'

DATASET_ID = 'sdr7-6v3j'
DOMAIN     = 'www.dallasopendata.com'
TOKEN      = 'BtnO9PupE2Ts6pg4JacdTe8JA'
META       = "https://#{DOMAIN}/api/views/metadata/v1/#{DATASET_ID}"

def scrape(options)
  loop do
    s          = Storage.new
    storehouse = "#{ENV['HOME']}/#{s.storage}/#{s.project}_#{Hamster.project_number}/"
    break if File.exists?("#{storehouse}stop")
    
    DallasPoliceArrestsRun.create!(status: 'processing') unless DallasPoliceArrestsRun.last&.status == 'processing'
    current_run = DallasPoliceArrestsRun.last
    
    time_at       = -> t, z { t.in_time_zone(z) }
    zone          = "Central America"
    dataset       = DallasPoliceArrestsUpdate
    existing_rows = dataset.where(deleted: false)
    first_run     = existing_rows.empty?
    results       = nil
    retries       = 0
    
    begin
      results = SODA::Client.new({ domain: DOMAIN, app_token: TOKEN, timeout: 30 }).get(DATASET_ID, :$limit => 1_000_000) if retries <= 10
    rescue Exception => e
      retries += 1
      
      report(to: 'Art Jarocki', message: "Project # 0013:\n#{e.full_message}", use: :both)
      
      sleep(60 - rand(30))
      retry
      report(to: 'Art Jarocki', message: 'Retries count reached *10*.', use: :both)
    end
    
    unless first_run
      meta        = JSON(connect_to(META).body).to_h.with_indifferent_access
      last_update = time_at[Time.parse(meta[:dataUpdatedAt]), zone]
      last_run    = time_at[dataset.all.last.updated_at, zone]
      
      puts "Last the source update was at #{last_update}".yellow
      
      while last_run > last_update
        meta        = JSON(connect_to(META).body).to_h.with_indifferent_access
        last_update = time_at[Time.parse(meta[:dataUpdatedAt]), zone]
        countdown(3600, header: 'Waiting for the source update...'.yellow, label: 'Next run in')
      end
    end
    
    if results
      results.each_with_index do |arrest, idx|
        print "\rCurrent ID: #{idx + 1} | Total: #{results.size}".green
        
        arrest.md5_hash = Digest::MD5.hexdigest arrest.values.join('')
        data            = dataset.flail { |k| [k, arrest[k]] }
        
        if first_run
          data[:arresteename_cleaned] = clean(data[:arresteename])
          store(dataset, data, current_run)
          
          next
        end
        
        existing_row = nil
        retries      = 0
        
        begin
          existing_row = existing_rows.find_by(arrestnumber: arrest.arrestnumber)
        rescue Exception => e
          retries += 1
          retry if retries <= 10
          if retries <= 10
            Hamster.countdown(3, header: "Error '#{e.message}' occurred while tried to get data from DB", label: 'Waiting before retry')
          end
          
          report(to: 'Art Jarocki', message: "Project # 0013:\n#{e.full_message}", use: :both)
          log e
        end
        
        if existing_row
          if existing_row.md5_hash == arrest.md5_hash
            existing_row.update(touched_run_id: current_run.id)
          else
            existing_row.update(deleted: true)
            data[:arresteename_cleaned] = existing_row.arresteename_cleaned_manually ? existing_row.arresteename_cleaned : clean(data[:arresteename])
            store(dataset, data, current_run)
          end
        else
          data[:arresteename_cleaned] = clean(data[:arresteename])
          store(dataset, data, current_run)
        end
      end
      
      puts
    end
    
    retries = 0
    
    begin
      dataset.where(deleted: false).where.not(touched_run_id: current_run.id).each { |row| row.update(deleted: true) }
      DallasPoliceArrestsRun.find_by(id: current_run.id).update(status: 'done')
    rescue Exception => e
      retries += 1
      if retries <= 10
        Hamster.countdown(3, header: "Error '#{e.message}' occurred while tried to put data to DB", label: 'Waiting before retry')
      end
      
      report(to: 'Art Jarocki', message: "Project # 0013:\n#{e.full_message}", use: :both)
      log e
    end
    
    report(to: 'Art Jarocki', message: 'Project # 0013 done a round.', use: :telegram)
  end
  
  report(to: 'Art Jarocki', message: 'Project # 0013 stopped scrape.', use: :telegram)
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
    retries += 1
    if retries <= 10
      Hamster.countdown(3, header: "Error '#{e.message}' occurred while tried to put data to DB", label: 'Waiting before retry')
    end
    
    report(to: 'Art Jarocki', message: "Project # 0013:\n#{e.full_message}", use: :both)
    log e
  end
end
