# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'
require_relative 'connector'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def scrape
    alphabet_array = ('a'..'z').to_a
    loop do
      retry_count = 0
      letter = alphabet_array.shift

      break if letter.nil?

      file_path = "#{store_file_path}/#{letter}.dat"
      next if File.exists?(file_path)

      begin
        member_id_list = []
        hsba_scraper = Scraper.new(nil, letter)
        hsba_scraper.scrape do |member_data|
          member_id_list << member_data.last unless member_data.nil?
        end
        store_member_ids(file_path, member_id_list)
        logger.info "project_0532: Scraped with last_name: #{letter} -> #{member_id_list.uniq.count} "
      rescue StandardError => e
        logger.info "project_0532: Error(#{letter}) -> #{e.full_message}"
        retry_count += 1

        retry if retry_count < 3

        alphabet_array << letter
        sleep(300)
      end
    end

    connector = HsbaConnector.new(Scraper::START_PAGE)
    files = Dir["#{store_file_path}/*"]

    files.each do |file_path|
      file_data   = File.read(file_path).split
      added_count = 0
      loop do
        retry_count = 0

        begin
          member_id = file_data.shift

          break if member_id.nil?

          member_page_url = "https://hsba.org/HSBA/Directory/Directory_results.aspx?ID=#{member_id}"
          member_page     = connector.do_connect(member_page_url)
          hash_data       = @parser.process_page(member_page.body)
          @keeper.insert_record(hash_data.merge(data_source_url:  member_page_url))
          added_count += 1
        rescue StandardError => e
          @logger.info("retry(#{retry_count}): #{file_path}")
          @logger.info(e.full_message)

          file_data << member_id
          retry_count += 1

          raise e if retry_count > 5

          retry
        end
      end
      File.delete(file_path) if File.exist?(file_path)
    end

    @keeper.update_history
    @keeper.finish
    Hamster.report(to: 'U04JS3K201J', message: "project_0532: Scrape Done! - #{@keeper.run_id}")
  end

  private

  def store_member_ids(file_path, member_list)
    File.open(file_path, 'w+') do |f|
      f.puts(member_list.uniq)
    end
  end

  def store_file_path
    file_path = "#{storehouse}store/#{@keeper.run_id}"
    FileUtils.mkdir_p(file_path)
    file_path
  end
end
