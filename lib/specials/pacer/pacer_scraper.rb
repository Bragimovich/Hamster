require_relative 'file_splitter'
require_relative 'us_courts_templates'
require_relative 'tables_generator'
require_relative 'hash_convertor'
require 'pry'
require 'get_process_mem'
require 'malloc_trim'

class PacerScraper < Hamster::Scraper
  include FileSplitter
  include TablesGenerator

  PROCESSING = 'processing'
  WAITING    = 'waiting'
  DONE       = 'done'
  SECONDS_IN_DAY = 86400

  JSON_SUBFOLDER = 'json/'

  def initialize(task_id)
    super
    @username   = 'mc3866'
    @password   = 'Record04'
    @task_id = task_id
    get_court_info
    generate_tables_if_not_exist(@court)
    generate_classes
  end

  def get_court_info
    @court = UsCourtTemplates.find_by(task_id: @task_id)
    @court_abbr = @court.court_abbr
  end
  
  def start
    is_first_run = @runs_class.last.nil?
    if is_first_run
      manage_download
    end

    loop do
      begin
        p 'inside loop'
        last_run = @runs_class.last
        if last_run.status == PROCESSING
          p '1'
          if last_run.downloading_status == PROCESSING
            p '1.1'
            Hamster.report to: 'eldar.mustafaiev', message: "#{@court.court_name.downcase.gsub(' ', '_')} download probably was restarted"
            manage_download(last_run.id)
          elsif last_run.downloading_status == DONE && last_run.storing_status == PROCESSING
            p '1.2'
            sleep(3600)
            next
          end
        elsif last_run.status == DONE
          p '2'
          manage_download
        end
        p '3'
        sleep(900)
      rescue => e
        p 'inside rescue'
        p e
      end
    end
  end

  def manage_download(id=nil)
    if id.nil?
      id = @runs_class.create.id
    end

    mem = GetProcessMem.new
    puts mem.inspect
    multiple_thread_download
    puts mem.inspect

    @runs_class.find(id).update(downloading_status: DONE)

    GC.start
    MallocTrim.trim
    puts mem.inspect
    
    sleep(SECONDS_IN_DAY)
  end

  def multiple_thread_download
    years = (2016..Time.now.year).to_a
    threads_count = years.size

    @semaphore = Mutex.new
    threads = Array.new(threads_count) do |thread_num|
      Thread.new do
        loop do
          year = nil
          @semaphore.synchronize {
            begin
              year = years.pop
            rescue StandardError => e
              year = nil
            end
          }
          break if year.nil?

          begin
            download_files(year)
          rescue StandardError => e
          end
        end
      end
    end

    threads.each(&:join)
  end

  def download_files(year)

    login_data = {
        username:   @username,
        password:   @password,
        court_id:   @court_abbr,
    }
    

    files_to_trash(year)
    
    court = Pacer.new(**login_data)
    json_hash = {}

    project_folder = "project_#{sprintf('%04d', @task_id)}"
    Dir.mkdir("#{ENV['HOME']}/HarvestStorehouse/#{project_folder}/store/#{JSON_SUBFOLDER}") unless File.exists?(
        "#{ENV['HOME']}/HarvestStorehouse/#{project_folder}/store/#{JSON_SUBFOLDER}"
    )
    json_storage_path = "#{ENV['HOME']}/HarvestStorehouse/#{project_folder}/store/#{JSON_SUBFOLDER}cases#{year}.json"

    court.cases_links(from: "1/1/#{year}", to: "12/31/#{year}") do |el|
      json_hash[el[:id]] = el[:is_open] unless el[:id].empty?
      unless el[:is_open]
        court_case = @case_info_class.find_by(case_id: el[:id])
        unless court_case.nil?
          next if court_case.status_as_of_date.include? 'Closed'
        end
      end

      begin
        body = court.docket_page(el[:link]).body
        url = el[:link].href.gsub(/^iquery.pl\?/, '')
        status = el[:is_open] ? 'Open' : 'Closed'
        save_files(body, url, status, el[:id], year)
      rescue StandardError => e
      end
    end
    
    File.open(json_storage_path,"w") do |f|
      f.write(JSON.pretty_generate(json_hash))
    end
  end

  private
  
  def generate_classes
    case_info_table = "#{@court_abbr}_case_info"
    @case_info_class = generate_class(case_info_table)

    runs_table = "#{@court_abbr}_runs"
    @runs_class = generate_class(runs_table)
  end

  def generate_class(table)
    code = <<-HEREDOC 
            Class.new(ActiveRecord::Base) do
              def self.name
                '#{table}'
              end
              self.table_name = '#{table}'
              establish_connection(Storage[host: :db01, db: :us_court_cases])
            end 
          HEREDOC
    eval(code)
  end
  

  def save_files(html, url, status, case_id, year)
    subfolder = @court.court_name.downcase.gsub(' ', '_')
    peon.put content: create_content(html, url, status, case_id), file: "#{year}#{Time.now.to_i.to_s}", subfolder: subfolder
  end

  def files_to_trash(year)
    trash_folder = @court.court_name.downcase.gsub(' ', '_')
      peon.list.each do |zip|
        peon.give_list_year(subfolder: zip, year: year).each do |file|
          peon.move(file: file, from: zip, to: trash_folder)
        end
      end
  end
end