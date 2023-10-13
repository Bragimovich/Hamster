# frozen_string_literal: true

require 'get_process_mem'
require 'malloc_trim'

require_relative '../lib/scraper'
require_relative '../lib/html_pages'
require_relative '../lib/hash_convertor'
require_relative '../models/runs'
require_relative '../models/us_case_courts'

PROCESSING = 'processing'
WAITING    = 'waiting'
DONE       = 'done'

def scrape(options)
  # if options[:download]
  #   begin
  #     loop do
  #       last_run = Runs.last
  #       if last_run.status == PROCESSING
  #         if last_run.downloading_status == PROCESSING
  #           report to: 'anton.storchak', message: "southern_district_ohio_court_scrape downloading #{PROCESSING} more than 24 hours."
  #           last_run = nil # clean memory
  #           sleep(900)
  #           next
  #         elsif last_run.downloading_status == DONE && last_run.storing_status == PROCESSING
  #           last_run = nil # clean memory
  #           sleep(3600)
  #           next
  #         end
  #       elsif last_run.status == DONE
  #         id = Runs.create.id
  #
  #         multiple_thread_download
  #
  #         Runs.find(id).update(downloading_status: DONE)
  #         next_day_time = DateTime.now.next_day
  #         sleep_time = (Time.new(next_day_time.year, next_day_time.month, next_day_time.day, 1, 0, 0) - Time.now).to_i
  #         sleep_time -= 300
  #         last_run = nil # clean memory
  #
  #         GC.start
  #         MallocTrim.trim
  #
  #         sleep(sleep_time)
  #       end
  #     end
  #   rescue StandardError => e
  #     report to: 'anton.storchak', message: "southern_district_ohio_court_scrape downloading failed #{e}"
  #     p e
  #     p e.backtrace
  #   end
  # elsif options[:store]
  #   begin
  #     loop do
  #       last_run = Runs.last
  #       if last_run.status == PROCESSING
  #         if last_run.downloading_status == DONE && last_run.storing_status == WAITING
  #           Runs.find(last_run.id).update(storing_status: PROCESSING)
  #           HTMLPages.new.process_current_pages(last_run.id)
  #           Runs.find(last_run.id).update(storing_status: DONE, status: DONE)
  #         elsif last_run.downloading_status == PROCESSING
  #           # ignore
  #         elsif last_run.downloading_status == DONE && last_run.storing_status == PROCESSING
  #           HTMLPages.new.process_current_pages(last_run.id)
  #           Runs.find(last_run.id).update(storing_status: DONE, status: DONE)
  #         end
  #       elsif last_run.status == DONE
  #         # ignore
  #       end
  #       last_run = nil # clean memory
  #
  #       GC.start
  #       MallocTrim.trim
  #
  #       sleep(3600)
  #     end
  #   rescue StandardError => e
  #     report to: 'anton.storchak', message: "southern_district_ohio_court_scrape storing failed #{e}"
  #     p e
  #     p e.backtrace
  #   end
  # elsif options[:init_court]
  #   save_init_court
  # end
end

def save_init_court
  run_id = 1
  court_id = 36
  court_name = 'District Court for the Southern District of Ohio'
  court_state = 'OH'
  court_type = 'Federal'
  court_sub_type = 'District'

  md5 = HashConvertor.new.court_to_md5(court_name, court_state, court_type, court_sub_type)
  court = UsCaseCourts.new
  court.run_id = run_id
  court.court_id = court_id
  court.court_name = court_name
  court.court_state = court_state
  court.court_type = court_type
  court.court_sub_type = court_sub_type
  court.data_source_url = "https://pacer.login.uscourts.gov/csologin/login.jsf"
  court.touched_run_id = 1
  court.md5_hash = md5
  court.save
end

def multiple_thread_download
  years = (2016..Time.now.year).to_a
  threads_count = years.size

  @semaphore = Mutex.new
  threads = Array.new(threads_count) do |thread_num|#5
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
          Scraper.new.download_files_for_year(year)
        rescue StandardError => e
        end
      end
    end
  end

  threads.each(&:join)
end