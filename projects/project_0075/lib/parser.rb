# frozen_string_literal: true

require 'yaml'

class BuildingPermitsParser < Hamster::Parser
  SOURCE = 'https://www2.census.gov'
  SUB_PATH = '/econ/bps/County/'
  SUB_FOLDER = 'building_permits_by_county/'
  DAY = 86400
  TEN_MINUTES = 600
  FIVE_MINUTES = 300



  def is_blank?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_children_are_blank?(node)
    node.children.all? {|child| is_blank?(child)}
    # Here you see the convenience of monkeypatching... sometimes.
  end

  def strip_trailing_spaces(text)
    text.strip.reverse.strip.reverse
  end

  def parse_page_links(main_page)
    html_text = Nokogiri::HTML(main_page).text
    correct_links = []

    rows = html_text.split("\n")

    # Skips links that do not end with "c" as was requested.

    rows.each do |link_name|
      next if link_name[0..1] != "co" || link_name[6..7] != "c."
      correct_links << link_name
    end
    correct_links
  end

  def parse(file_content, file, run_id)
    begin
      @run_id = run_id
      mysql_insertion_ary = []
      file_name = file.gsub('.gz', '')
      logger.debug file_name

      parsed = Nokogiri::HTML(file_content).text
      parsed_ary = parsed.split("\n")

      page_rows = []
      num = 0

      # Takes the full page of data containing all information and skips the first three lines as they are irrelevant.
      # It creates an array, one element being one row of text from the page.

      parsed_ary.each do |row_of_data_from_page|
        num += 1
        next if num == 1 || num == 2 || num == 3

        data = row_of_data_from_page.split(",")
        data[-1].gsub!(/\r/, "")
        page_rows << data
      end

    

      yaml_storage_path = "#{ENV['HOME']}/HarvestStorehouse/project_0075/store/yaml/rows.yml"
      additional_info = YAML.load(File.read(yaml_storage_path)).group_by{|el| el[0]}
      additional_info = additional_info.each {|key,val| additional_info[key] = val[0][1]}


      run_id    = @run_id
      link      = additional_info[file_name][0]
      date      = additional_info[file_name][1]

      # Takes a row from the page and selects each piece of individual information and sets it equal to its proper variable.

      page_rows.each do |row|

        # Adds data in correct format to a new array so it can be mass inserted into the mySQL table.

        mysql_insertion_ary << {run_id: run_id,
          date: date,
          survey_date: row[0].strip.reverse.strip.reverse,
          FIPS_state:  row[1].strip.reverse.strip.reverse,
          FIPS_county: row[2].strip.reverse.strip.reverse,
          region_code: row[3].strip.reverse.strip.reverse,
          division_code: row[4].strip.reverse.strip.reverse,
          county_name: row[5].strip.reverse.strip.reverse,
          one_unit_bldgs: row[6].strip.reverse.strip.reverse,
          one_unit_units: row[7].strip.reverse.strip.reverse,
          one_unit_value: row[8].strip.reverse.strip.reverse,
          two_units_bldgs: row[9].strip.reverse.strip.reverse,
          two_units_units: row[10].strip.reverse.strip.reverse,
          two_units_value: row[11].strip.reverse.strip.reverse,
          three_four__units_bldgs: row[12].strip.reverse.strip.reverse,
          three_four__units_units: row[13].strip.reverse.strip.reverse,
          three_four__units_value: row[14].strip.reverse.strip.reverse,
          fiveplus__units_bldgs: row[15].strip.reverse.strip.reverse,
          fiveplus__units_units: row[16].strip.reverse.strip.reverse,
          fiveplus__units_value: row[17].strip.reverse.strip.reverse,
          one_units_rep_bldgs: row[18].strip.reverse.strip.reverse,
          one_units_rep_units: row[19].strip.reverse.strip.reverse,
          one_units_rep_value: row[20].strip.reverse.strip.reverse,
          two_units_rep_bldgs: row[21].strip.reverse.strip.reverse,
          two_units_rep_units: row[22].strip.reverse.strip.reverse,
          two_units_rep_value: row[23].strip.reverse.strip.reverse,
          three_four__units_rep_bldgs: row[24].strip.reverse.strip.reverse,
          three_four__units_rep_units: row[25].strip.reverse.strip.reverse,
          three_four__units_rep_value: row[26].strip.reverse.strip.reverse,
          fiveplus__units_rep_bldgs: row[27].strip.reverse.strip.reverse,
          fiveplus__units_rep_units: row[28].strip.reverse.strip.reverse,
          fiveplus__units_rep_value: row[29].strip.reverse.strip.reverse,
          link: additional_info[file_name][0],
          scrape_frequency: scrape_frequency,
          data_source_url: data_source_url}
      end
        mysql_insertion_ary
    rescue => e
      logger.debug e.full_message
      logger.debug file
      logger.debug 'last'
      Hamster.report(to: 'seth.putz', message: "Project # 0075 --store: Error - \n#{e} \n#{file}, went to sleep for 10 min", use: :both)
      sleep(TEN_MINUTES)
    end
  end
end
