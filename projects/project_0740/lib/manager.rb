# frozen_string_literal: true

require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'
require_relative '../models/us_case_info'
require_relative '../models/il_cccc_case_ids_temp'
require_relative '../models/il_cccc_case_info'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @run_id = keeper.run_id
    @inserted_cases = @keeper.get_cases()
  end

  def download_missing
    scraper = Scraper.new
    parser = Parser.new
    array = ['CH', 'L', 'D']
    response = scraper.fetch_main_page
    tokens = parser.get_access_token(response)

    token_iterator = 0
    nocase_iterator = 0
    flag = false

    years = [2018, 2019, 2020, 2021, 2022]

    years.each do |year|

      array.each do |latter|
        token_iterator = 0
        nocase_iterator = 0

        id = 1
        max_id = IlCcccCaseInfo.where("case_id LIKE ?", "%#{year}#{latter}%").maximum(:case_id)
        max_id = max_id.split(latter).last.to_s rescue ""

        while true

          if token_iterator > 50
            response = scraper.fetch_main_page
            tokens = parser.get_access_token(response)
            token_iterator = 0
          end

          break if nocase_iterator > 50

          if latter.include? "L"
            tokens[:type] = 2
          elsif latter.include? "CH"
            tokens[:type] = 3
          elsif latter.include? "D"
            tokens[:type] = 4
          end

          no = prepare_zeros(id,latter )
          case_id = "#{year}#{latter}#{no}"
          break if case_id == max_id

          id += 1
          next if @inserted_cases.include? case_id
          Hamster.logger.debug case_id
          response = scraper.fetch_case(tokens, case_id)

          if response.body.include? "No Cases Found:" or response.body.include? "Please enable JavaScript to view the page content" or response.body.include? "Service Unavailable"
            nocase_iterator += 1
            next
          else
            nocase_iterator = 0
          end

          save_file(response, case_id)
          token_iterator += 1
        end
      end
    end

  end


  def download_latest
    scraper = Scraper.new
    parser = Parser.new
    array = ['CH', 'L', 'D']
    response = scraper.fetch_main_page
    tokens = parser.get_access_token(response)

    token_iterator = 0
    nocase_iterator = 0
    flag = false
    year = Date.today.year
    array.each do |latter|
      token_iterator = 0
      nocase_iterator = 0

      id = IlCcccCaseInfo.where("case_id LIKE ?", "%#{year}#{latter}%").maximum(:case_id)
      id = id.split(latter).last.to_i

      while true

        if token_iterator > 50
          response = scraper.fetch_main_page
          tokens = parser.get_access_token(response)
          token_iterator = 0
        end

        break if nocase_iterator > 50

        if latter.include? "L"
          tokens[:type] = 2
        elsif latter.include? "CH"
          tokens[:type] = 3
        elsif latter.include? "D"
          tokens[:type] = 4
        end

        no = prepare_zeros(id,latter )
        case_id = "#{year}#{latter}#{no}"

        if @inserted_cases.include? case_id
          id = id + 1
          next
        end

        Hamster.logger.debug case_id
        response = scraper.fetch_case(tokens, case_id)
        id += 1

        if response.body.include? "No Cases Found:" or response.body.include? "Please enable JavaScript to view the page content" or response.body.include? "Service Unavailable"
          nocase_iterator += 1
          next
        else
          nocase_iterator = 0
        end

        save_file(response, case_id)
        token_iterator += 1
      end
    end
  end

  def store
    parser = Parser.new
    files = peon.list().delete_if { |x| x == ".DS_Store" }
    files.each do |file|
      next if @inserted_cases.include? file.gsub(".gz", "")
      Hamster.logger.debug "Processing Case Id -----------> #{file}"

      file_content = get_content(file)
      data_hash = parser.parse_case_info(file_content, @run_id)
      if data_hash[:case_id].nil?
        data = {}
        data[:case_id] = file.gsub(".gz", "")
        next
      end
      keeper.insert_case_info(data_hash) unless data_hash.empty?
      data_array = parser.parse_case_party(file_content, @run_id)
      keeper.insert_case_party(data_array) unless data_array.empty?
      data_array = parser.parse_case_activities(file_content, @run_id)
      keeper.insert_case_activities(data_array) unless data_array.empty?
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :sub_folder

  def get_content(file)
    peon.give(file: file)
  end

  def prepare_zeros(int, latter)
    if latter == "CH"
      no = 5
    else
      no = 6
    end
    zeros_count = no - int.to_s.length
    zeros_count = [zeros_count, 0].max # Ensure the count is not negative

    zeros = "0" * zeros_count
    str = zeros + int.to_s

    return str
  end

  def save_pdf(content, file_name, sub_folder)
    pdf_storage_path = "#{storehouse}store/#{sub_folder}/#{file_name}"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(response, file_name)
    peon.put content: response.body, file: file_name
  end

end
