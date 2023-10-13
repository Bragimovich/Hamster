# frozen_string_literal: true

require_relative '../models/dallas_police_active_calls_update'

# DATASET_ID = 'rtzi-mds8'
DATASET_ID = '9fxf-t2tr'
DOMAIN     = 'www.dallasopendata.com'
TOKEN      = 'BtnO9PupE2Ts6pg4JacdTe8JA'
META       = "https://#{DOMAIN}/api/views/metadata/v1/#{DATASET_ID}"

def scrape(options)
  debug = Hamster.commands[:debug]
  
  loop do
    s          = Storage.new
    storehouse = "#{ENV['HOME']}/#{s.storage}/#{s.project}_#{Hamster.project_number}/"
    break if File.exists?("#{storehouse}stop")
    
    dataset = DallasPoliceActiveCallsUpdate
    results = nil
    retries = 0
    
    begin
      meta        = JSON(connect_to(META).body).to_h.with_indifferent_access
      last_update = Time.parse(meta[:dataUpdatedAt]) - 6.hours
      results     = SODA::Client.new({ domain: DOMAIN, app_token: TOKEN, timeout: 30 }).get(DATASET_ID) if retries <= 10
    rescue Exception => e
      report(to: 'Art Jarocki', message: "Project # 0014:\n#{e.full_message}", use: :both)
      
      retries += 1
      sleep(60 - rand(30))
      retry
      report(to: 'Art Jarocki', message: 'Retries count reached *10*.', use: :both)
    end
    
    if results
      md5_keys = results.map do |call|
        call.location = call.location.encode("UTF-16be", :invalid => :replace, :replace => "?").encode('UTF-8') unless call.location.valid_encoding?
        call.md5_hash = Digest::MD5.hexdigest call.values.join('')
        call[:md5_hash]
      end
      
      retries = 0
      
      begin
        done_calls = dataset.where('date > ?', "#{Date.parse((last_update - 3.days).to_s)}T00:00:00.000").where.not(md5_hash: md5_keys).where(done_at: nil)
        done_calls.each do |call|
          call.done_at = last_update
          data         = dataset.flail { |k| [k, call[k]] }
          dataset.find_by(md5_hash: call.md5_hash).update(data)
        end
      rescue Exception => e
        retries += 1
        if retries <= 10
          Hamster.countdown(2**retries, header: "Error '#{e.message}' occurred while tried to get data from DB", label: 'Waiting before retry')
        end
        
        report(to: 'Art Jarocki', message: "Project # 0014:\n#{e.full_message}", use: :both)
        log e
      end
      
      puts 'Just wait, please...'.yellow if debug
      
      results.each do |call|
        next if call.done_at
        
        retries = 0
        begin
          call_exists = dataset.find_by(md5_hash: call.md5_hash)
        rescue => e
          sleep 2 ** retries
          retries += 1
          if retries <= 10
            Hamster.countdown(3, header: "Error '#{e.message}' occurred while tried to put data to DB", label: 'Waiting before retry')
          end
          
          report(to: 'Art Jarocki', message: "Project # 0014:\n#{e.full_message}", use: :both)
          log e
        else
          next if call_exists
        end
        
        data    = {}
        retries = 0
        begin
          data = dataset.flail { |k| [k, call[k]] }
        rescue Exception => e
          sleep 2 ** retries
          retries += 1
          if retries <= 10
            Hamster.countdown(3, header: "Error '#{e.message}' occurred while tried to put data to DB", label: 'Waiting before retry')
          end
          
          report(to: 'Art Jarocki', message: "Project # 0014:\n#{e.full_message}", use: :both)
          log e
        end
        
        retries = 0
        begin
          dataset.store(data)
        rescue Exception => e
          sleep 2 ** retries
          retries += 1
          if retries <= 10
            Hamster.countdown(3, header: "Error '#{e.message}' occurred while tried to put data to DB", label: 'Waiting before retry')
          end
          
          report(to: 'Art Jarocki', message: "Project # 0014:\n#{e.full_message}", use: :both)
          log e
        end
      end
      
      countdown(30, label: 'Next run in')
      
      puts if debug
    end
  
  end
  
  report(to: 'Art Jarocki', message: 'Project # 0014 stopped scrape.', use: :telegram)
end
