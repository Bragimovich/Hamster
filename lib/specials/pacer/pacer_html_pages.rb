require 'json'
require_relative 'us_courts_templates'
require_relative 'file_splitter'
require_relative 'pacer_parser'
require 'get_process_mem'
require 'malloc_trim'

class PacerHTMLPages < Hamster::Scraper
  include FileSplitter

  PROCESSING = 'processing'
  WAITING    = 'waiting'
  DONE       = 'done'

  THREADS_COUNT = 5
  JSON_SUBFOLDER = 'json/'

  def initialize(task_id)
    super
    @task_id = task_id
    get_court_info
    generate_classes
  end
  
  def start
    loop do
      last_run = @runs_class.last
      if last_run.status == PROCESSING
        if last_run.downloading_status == DONE && last_run.storing_status == WAITING
          @runs_class.find(last_run.id).update(storing_status: PROCESSING)
          process_current_pages(last_run.id)
          @runs_class.find(last_run.id).update(storing_status: DONE, status: DONE)
        elsif last_run.downloading_status == PROCESSING
          # ignore
        elsif last_run.downloading_status == DONE && last_run.storing_status == PROCESSING
            process_current_pages(last_run.id)
            @runs_class.find(last_run.id).update(storing_status: DONE, status: DONE)
        end
      elsif last_run.status == DONE
        # ignore
      end
      sleep(3600)
    end
  end

  def process_current_pages(run_id)
    mem = GetProcessMem.new
    puts mem.inspect
    
    @run_id = run_id
    process_each_file
    finish_parse
    
    puts mem.inspect

    GC.start
    MallocTrim.trim
    puts mem.inspect
  end

  private

  def get_court_info
    @court = UsCourtTemplates.find_by(task_id: @task_id)
    @court_abbr = @court.court_abbr
  end

  def generate_classes
    runs_table = "#{@court_abbr}_runs"
    @runs_class = generate_class(runs_table)

    case_info_table = "#{@court_abbr}_case_info"
    @case_info_class = generate_class(case_info_table)

    case_party_table = "#{@court_abbr}_case_party"
    @case_party_class = generate_class(case_party_table)

    case_activities_table = "#{@court_abbr}_case_activities"
    @case_activities_class = generate_class(case_activities_table)
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

  def process_each_file
    subfolder = @court.court_name.downcase.gsub(' ', '_')
    
    peon.list.each do |zip|
      if zip == 'json'
        years = (2016..Time.now.year).to_a
        project_folder = "project_#{sprintf('%04d', @task_id)}"

        @current_cases_hash = {}
        years.each do |year|
          begin
            file = File.read("#{ENV['HOME']}/HarvestStorehouse/#{project_folder}/store/#{JSON_SUBFOLDER}cases#{year}.json")
            new_hash = JSON.parse(file)
            new_hash&.each do |key, value|
              @current_cases_hash[key] = value unless value
            end
          rescue StandardError => e
          end
        end
      elsif zip == subfolder
        files = peon.give_list(subfolder: zip)

        @semaphore = Mutex.new
        threads = Array.new(THREADS_COUNT) do |thread_num|#5
          Thread.new do
            loop do
              file_content = nil
              @semaphore.synchronize {
                begin
                  file_content = peon.give(subfolder: zip, file: files.pop)
                rescue StandardError => e
                  file_content = nil
                end
              }
              break if file_content.nil?

              p "CASE_ID: #{split_case_id(file_content)}"
              begin
                PacerParser.new(split_html(file_content), split_link(file_content), @run_id,
                           split_status(file_content), split_case_id(file_content), @case_party_class, @case_activities_class, @case_info_class, @court).parse_case
              rescue StandardError => e
                p e
              end
            end
          end
        end

        threads.each(&:join)
      end
    end
  end

  def finish_parse
    case_ids =  @current_cases_hash.keys.each_slice(1000).to_a
    case_ids.each do |range|
      @case_info_class.where(["touched_run_id < :touched_run_id and deleted = :deleted and case_id IN (:range)", { touched_run_id: @run_id, deleted: false, range: range }]).update_all(touched_run_id: @run_id)
      @case_party_class.where(["touched_run_id < :touched_run_id and deleted = :deleted and case_id IN (:range)", { touched_run_id: @run_id, deleted: false, range: range }]).update_all(touched_run_id: @run_id)
      @case_activities_class.where(["touched_run_id < :touched_run_id and deleted = :deleted and case_id IN (:range)", { touched_run_id: @run_id, deleted: false, range: range }]).update_all(touched_run_id: @run_id)
    end
    @case_info_class.where(["touched_run_id < :touched_run_id and deleted = :deleted", { touched_run_id: @run_id, deleted: false }]).in_batches.update_all(deleted: true)
    @case_party_class.where(["touched_run_id < :touched_run_id and deleted = :deleted", { touched_run_id: @run_id, deleted: false }]).in_batches.update_all(deleted: true)
    @case_activities_class.where(["touched_run_id < :touched_run_id and deleted = :deleted", { touched_run_id: @run_id, deleted: false }]).in_batches.update_all(deleted: true)
    peon.throw_trash
  end
end