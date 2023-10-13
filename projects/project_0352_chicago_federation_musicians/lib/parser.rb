# frozen_string_literal: true
require_relative 'scraper'
require_relative '../models/chicago_federation_musicians'

class Parser < Hamster::Parser
  SUBFOLDER = "chicago_federation_musicians"

  def parse_html(html, letter)
    doc = Nokogiri::HTML html  
    cfm_object = []
    doc.css('table').each_with_index do |table, index_table|
      begin
        table.search('tr').drop(1).each_with_index do |tr, index_tr|
          cfm_data_hash = {}
          tr.search('td').each_with_index do |td, index_td|
            logger.info td
            if index_td == 0
              logger.info td.children.children.text
              cfm_data_hash[:data_source_url] = "https://www.cfm10208.com"+td.children[0].attributes["href"].value
              scraper = Scraper.new
              response = scraper.fetch_phone_number(cfm_data_hash[:data_source_url], letter)
              user_detail_doc = Nokogiri::HTML(response)
              @phone_no = user_detail_doc.at_css("a#modal_open").parent.children[5].children.last&.text
              cfm_data_hash[:full_name] = user_detail_doc.css('.solid').children.text
              splited_name = split_full_name(user_detail_doc.css('.solid').children.text)
              cfm_data_hash[:first_name] = splited_name[:first_name]
              cfm_data_hash[:middle_name] = splited_name[:middle_name]
              cfm_data_hash[:last_name] = splited_name[:last_name]
            end
            if index_td == 2
              logger.info td.children[1].text.strip #primary
              cfm_data_hash[:primary] =  td.children[1].text.strip #primary

              logger.info td.children[3].text.strip #all
              cfm_data_hash[:all_instruments] =  td.children[3].text.strip #all
            end
            if index_td == 3
              logger.info td.children[2].text.strip
              cfm_data_hash[:phone_number] =  td.children[2].text.strip #phone no.
              cfm_data_hash[:phone_number] += ", #{@phone_no}" if cfm_data_hash[:phone_number] != @phone_no

              logger.info td.children[5].text.strip
              cfm_data_hash[:email] =  td.children[5].text.strip.gsub("<b>Email:</b> ", "").empty? ? "null" : td.children[5].text.strip.gsub("<b>Email:</b> ", "") #email
            end          
          end
          cfm_data_hash[:created_by] = 'Bhawna Pahadiya'
          cfm_data_hash[:scrape_frequencey] = 'yearly'
          cfm_data_hash[:year] = Time.now.year
          cfm_object << cfm_data_hash
        end
      rescue StandardError => e
        logger.debug e
        logger.debug e.backtrace
      end
    end
    begin
      file_name = "#{letter.parameterize}.json"
      peon.put content: cfm_object.to_json, file: "#{file_name}", subfolder: SUBFOLDER
    rescue StandardError => e
      logger.debug e
      logger.debug e.backtrace
    end
  end

  private

  def split_full_name(full_name_str)
    result = {first_name: nil, middle_name: nil, last_name: nil}

    names_arr = full_name_str.split(" ")
    if names_arr.size == 3
      begin
        result[:first_name] = names_arr[0].gsub(",", "")
      rescue StandardError => e
        logger.error e
        logger.error e.backtrace
      end

      begin
        result[:middle_name] = names_arr[1]
      rescue StandardError => e
        logger.error e
        logger.error e.backtrace
      end

      begin
        result[:last_name] = names_arr[2]
      rescue StandardError => e
        logger.error e
        logger.error e.backtrace
      end
    elsif names_arr.size == 2
      begin
        result[:last_name] = names_arr[1]
      rescue StandardError => e
        logger.error e
        logger.error e.backtrace
      end

      begin
        result[:first_name] = names_arr[0].gsub(",", "")
      rescue StandardError => e
        logger.error e
        logger.error e.backtrace
      end
    elsif names_arr.size > 3
      begin
        result[:first_name] = names_arr[0].gsub(",", "")
      rescue StandardError => e
        logger.error e
        logger.error e.backtrace
      end

      begin
        result[:last_name] = names_arr.last
      rescue StandardError => e
        logger.error e
        logger.error e.backtrace
      end

      begin
        middle_name = ""
        names_arr.pop
        names_arr.drop(1).each do |item|
          middle_name << item
          middle_name << " "
        end
        result[:middle_name] = middle_name.strip
      rescue StandardError => e
        logger.error e
        logger.error e.backtrace
      end
    end
    result
  end
end
