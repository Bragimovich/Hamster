require 'json'

require_relative 'file_splitter'
require_relative 'parser'

class HTMLPages < Hamster::Scraper
  include FileSplitter

  THREADS_COUNT = 5
  JSON_SUBFOLDER = 'json/'

  def process_current_pages(run_id)
    @run_id = run_id
    process_each_file
    finish_parse
  end

  private

  def process_each_file
    peon.list.each do |zip|
      if zip == 'json'
        years = (2016..Time.now.year).to_a

        @current_cases_hash = {}
        years.each do |year|
          begin
            file = File.read("#{ENV['HOME']}/HarvestStorehouse/project_0054/store/#{JSON_SUBFOLDER}cases#{year}.json")
            new_hash = JSON.parse(file)
            new_hash&.each do |key, value|
              @current_cases_hash[key] = value unless value
            end
          rescue StandardError => e
          end
        end
      elsif zip == 'southern_district_ohio_court'
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

              # sleep(rand(1.1..100.1))

              p "CASE_ID: #{split_case_id(file_content)}"
              begin
                Parser.new(split_html(file_content), split_link(file_content), @run_id,
                           split_status(file_content), split_case_id(file_content)).parse_case
              rescue StandardError => e
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
      UsCaseInfo.where(["touched_run_id < :touched_run_id and deleted = :deleted and case_id IN (:range)", { touched_run_id: @run_id, deleted: false, range: range }]).update_all(touched_run_id: @run_id)
      UsCaseParty.where(["touched_run_id < :touched_run_id and deleted = :deleted and case_id IN (:range)", { touched_run_id: @run_id, deleted: false, range: range }]).update_all(touched_run_id: @run_id)
      UsCaseActivities.where(["touched_run_id < :touched_run_id and deleted = :deleted and case_id IN (:range)", { touched_run_id: @run_id, deleted: false, range: range }]).update_all(touched_run_id: @run_id)
    end

    @current_cases_hash = nil # clean Memory

    UsCaseInfo.where(["touched_run_id < :touched_run_id and deleted = :deleted", { touched_run_id: @run_id, deleted: false }]).update(deleted: true)
    UsCaseParty.where(["touched_run_id < :touched_run_id and deleted = :deleted", { touched_run_id: @run_id, deleted: false }]).update(deleted: true)
    UsCaseActivities.where(["touched_run_id < :touched_run_id and deleted = :deleted", { touched_run_id: @run_id, deleted: false }]).update(deleted: true)

    peon.throw_trash

    @run_id = nil # clean Memory
  end
end