# frozen_string_literal: true

require 'date'
require 'json'
# require 'zlib'

# require_relative './database_manager'
require_relative '../models/us_patent'
require_relative '../models/us_patents_applicant'
# require_relative './main_logger'

class USPatentsParser < Hamster::Parser
  CREATED_BY = 'Sergii Butrymenko'

  def initialize
    super
    FileUtils.mkdir_p storehouse + 'log/'
    @logger = Logger.new(storehouse + 'log/' + "parsing_#{Date.today.to_s}.log", 'monthly', 50 * 1024 * 1024)
  end

  def parse
    @logger.info "Start parsing."
    waiting_hours = 0
    while waiting_hours <= 9
      file_list = peon.give_list.sort
      # file_list = peon.give_list(subfolder: found_dir).sort
      if file_list.empty?
        puts 'Sleeping 3 hours...'
        sleep(3 * 60 * 60)
        # sleep(3)
        waiting_hours += 3
        next
      else
        waiting_hours = 0
      end

      file_list.each do |file|
        puts "Processing #{file}"
        content = Nokogiri::HTML(peon.give(file: file)) #, subfolder: found_dir))
        table_list = content.css('table')

        patent_info = {}

        patent_info[:patent_nr] = table_list[2].css('td')[1].text.strip
        patent_info[:issue_date] = Date.parse(table_list[2].css('td')[3].text.strip)

        patent_info[:short_description] = content.css('hr')[1].next_element.text.strip.gsub("\n", ' ').squeeze(' ')
        abstract = content.css('center')[1].next_element.text.strip.gsub("\n", ' ').squeeze(' ')
        patent_info[:abstract] = abstract.empty? ? nil : abstract
        if abstract.empty?
          if content.at('center:contains("Claims")').nil?
            patent_info[:claims] = nil
          else
            claims = content.at('center:contains("Claims")').next_element.next.text.strip.sub(/^CLAIM\s+/, '').gsub("\n", ' ').squeeze(' ')
            patent_info[:claims] = claims.empty? ? nil : claims
          end
        end

        applicant_data = content.at('table:contains("Type")').css('td')

        applicant_name = split_list(applicant_data[2].text.strip)
        applicant_city = split_list(applicant_data[3].text.strip)
        applicant_state = split_list(applicant_data[4].text.strip)
        applicant_country = split_list(applicant_data[5].text.strip)
        # applicant_info[:applicant_name] = applicant_data[2].text.strip
        # applicant_city = applicant_data[3].text.strip
        # applicant_info[:applicant_city] = applicant_city == 'N/A' ? nil : applicant_city
        # applicant_state = applicant_data[4].text.strip
        # applicant_info[:applicant_state] = applicant_state == 'N/A' ? nil : applicant_state
        # applicant_country = applicant_data[5].text.strip
        # applicant_info[:applicant_country] = applicant_country == 'N/A' ? nil : applicant_country
        # patent_info[:applicant_type] = company_data[4].text.strip

        patent_info[:family_id] = content.at('th:contains("Family ID:")').nil? ? nil : content.at('th:contains("Family ID:")').next_element.text.strip
        # patent_info[:family_id] = table_list[3].at('th:contains("Family ID:")').next_element.text.strip
        patent_info[:application_nr] = content.at('th:contains("Appl. No.:")').next_element.text.strip
        patent_info[:filling_date] = Date.parse(content.at('th:contains("Filed:")').next_element.text.strip)

        date = file.split('_').first.split('-')
        counter = file.split('_').last.split('.').first.to_i
        year = date[0]
        month = date.count > 1 ? date[1] : '$'
        day = date.count > 2 ? date[2] : '$'

        patent_info[:data_source_url] = "https://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO2&Sect2=HITOFF&u=%2Fnetahtml%2FPTO%2Fsearch-adv.htm&r=#{counter}&f=G&l=50&d=PTXT&p=1&S1=#{year}#{month}#{day}.PD.&OS=ISD/#{month}/#{day}/#{year}&RS=ISD/#{year}#{month}#{day}"

        # puts JSON.pretty_generate(patent_info)

        if patent_info.empty?
          MainLogger.logger.warn("Can't parse primary content for page ID #{counter}")
          @logger.warn("Can't parse primary content for page ID #{counter}")
          report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Can't parse primary content for page ID #{counter}", use: :both)
          next
        else
          record = USPatent.new
          record.patent_nr = patent_info[:patent_nr]
          record.issue_date = patent_info[:issue_date]

          record.short_description = patent_info[:short_description]
          record.abstract = patent_info[:abstract]
          record.claims = patent_info[:claims]

          # record.applicant_name = patent_info[:applicant_name]
          # record.applicant_city = patent_info[:applicant_city]
          # record.applicant_state = patent_info[:applicant_state]
          # record.applicant_country = patent_info[:applicant_country]
          record.family_id = patent_info[:family_id]
          record.application_nr = patent_info[:application_nr]
          record.filling_date = patent_info[:filling_date]

          record.data_source_url = patent_info[:data_source_url]


          record.created_by = CREATED_BY
          record.last_scrape_date = Date.today
          if day == '$'
            record.next_scrape_date = Date.today.next_month
            record.frequency = 'monthly'
          else
            record.next_scrape_date = Date.today + 7
            record.frequency = 'weekly'
          end
          record.dataset_name_prefix = 'us_patents'
          record.scrape_status = 'live'
          record.pl_gather_task_id = nil
          begin
            record.save
          rescue ActiveRecord::ActiveRecordError => e
            @logger.error(e)
            raise
          end

          while applicant_name.empty? == false
            record_2 = USPatentsApplicant.new
            record_2.patent_nr = patent_info[:patent_nr]
            record_2.applicant_name = applicant_name.shift
            record_2.applicant_city = applicant_city.shift
            record_2.applicant_state = applicant_state.shift
            record_2.applicant_country = applicant_country.shift

            record_2.created_by = CREATED_BY
            record_2.last_scrape_date = Date.today
            record_2.next_scrape_date = Date.today.next_month
            record_2.frequency = day == '$' ? 'monthly' : 'weekly'
            record_2.dataset_name_prefix = 'us_patents'
            record_2.scrape_status = 'live'
            record_2.pl_gather_task_id = nil
            begin
              record_2.save
            rescue ActiveRecord::RecordNotUnique => e
              @logger.warn("RECORD NOT UNIQUE:\n#{e}")
            rescue ActiveRecord::ActiveRecordError => e
              @logger.error(e)
              raise
            end
          end


        end
        peon.move(file: file)
        # MainLogger.logger.info JSON.pretty_generate(primary_table).green
        # MainLogger.logger.info JSON.pretty_generate(secondary_table).yellow
      end
    end
    @logger.info "Parsing finished."
    rescue StandardError => e
      @logger.error(e)
      raise
  end

  private

  def split_list(str)
    str.split("\n").map{|item| item == 'N/A' ? nil : item}
  end
end
