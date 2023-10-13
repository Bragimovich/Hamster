# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
  end
  
  def download
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Download Started")
    scraper = Scraper.new(@keeper)
    subfolers_letters =  peon.list(subfolder: create_subfolder)
    first_letter = subfolers_letters.sort.last&.split('_')&.last || 'a'
    keeper.mark_as_started_download

    (first_letter..'z').each do |letter|
      subfolder_path = create_subfolder(letter)
      html = scraper.scrape_new_data(letter)
      parser = Parser.new(html)
      lawyers = parser.lawyers_list
      next if lawyers.empty?

      lawyers.each do |hash|
        lawyer_id = hash[:reg_num]
        file_name = 'lawyer_' + lawyer_id
        next if list_downloaded.include?(file_name + '.gz')

        lawyer_page = scraper.get_inner_record(hash[:link])
        save_file(lawyer_page, file_name, subfolder_path)
      end
    end
    keeper.mark_as_finished_download
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Download Done")
    Hamster.logger.info("_________________DOWNLOAD DONE___________________")
  end

  def store
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Store Started")
    keeper.mark_as_started_store
    letter_folders = (peon.list(subfolder: "#{keeper.run_id}").select { |s| s.include? 'letter_' }).sort

    letter_folders.each do |letter_folder|
      subfolder = "#{keeper.run_id}/#{letter_folder}"
      subfolder_files = peon.give_list(subfolder: subfolder).select { |file| file.include? 'lawyer_' }

      subfolder_files.each do |file|
        html = peon.give(file: file, subfolder: subfolder)
        parser = Parser.new html
        data_hash = parser.lawyer_data(keeper.run_id)
        next if data_hash.empty?

        keeper.store_data data_hash
      end
    end
    keeper.update_delete_status
    keeper.finish
    clear
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Store finished")
  end

  private

  attr_accessor :keeper, :parser

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def create_subfolder(letter = nil)
    data_set_path = "#{storehouse}store/#{keeper.run_id}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)

    if letter.present?
      data_set_path = "#{data_set_path}/letter_#{letter}"
      FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    end

    data_set_path.split("store/").last
  end

  def list_downloaded
    subfolers_letters = peon.list(subfolder: "#{keeper.run_id}")
    return [] if subfolers_letters.empty?

    subfolers_letters.each_with_object(Array.new) do |folder, arr|
      arr << peon.give_list(subfolder: "#{keeper.run_id}/#{folder}").select { |file| file.include? 'lawyer_' }
    end.flatten
  end

  def clear
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "ks_court_run_#{keeper.run_id}_time_#{time}"

    peon.list(subfolder: "#{keeper.run_id}").each do |folder_l|
      peon.give_list(subfolder: "#{keeper.run_id}/#{folder_l}").each do |file_name|  
        peon.move(file: "#{file_name}", from: "#{keeper.run_id}/#{folder_l}", to: "#{trash_folder}/#{folder_l}")
      end
    end

    peon.throw_trash(5)
  end
end
