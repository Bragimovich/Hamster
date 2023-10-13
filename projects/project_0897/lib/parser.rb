# frozen_string_literal: true

class Parser < Hamster::Parser

  CONFERENCES_URL_PREFIX = "https://ihsa.org/data/fb/"

  def parse_html(body)
    Nokogiri::HTML(body)
  end

  def get_conferences_link(response)
    page = parse_html(response.body)
    conferences_link = []
    all_links = page.css("h3 a")
    all_links.each do |link|
      url = CONFERENCES_URL_PREFIX + link.attr("href")
      conferences_link.push(url)
    end
    conferences_link
  end

  def get_teams_and_conference(page)
    data_array = []
    season = page.css("h1").text.split("\u0097").last
    all_tables = page.css("table.dg")
    all_tables.each do |table|
      # getting nearest h3 to stop the loop 
      h3_element = table.previous
      while h3_element&.name != "h3" && h3_element&.name != "body"
        h3_element = h3_element.previous
      end
      
      all_rows = table.css("tr")
      all_rows.each_with_index do |row, ind|
        next if ind < 3
        data_hash = {}
        data_hash["conf_name"] = h3_element.text
        data_hash["season"] = season
        data_hash["team_name"] = row.css("td")[1].text
        data_hash["data_source_url"] = CONFERENCES_URL_PREFIX + "confall.htm"
        data_hash = mark_empty_as_nil(data_hash)
        data_array.push(data_hash)
      end
    end
    data_array
  end

  def get_standings_data(page, file_name)
    data_array = []
    all_tables = page.css("table.dg")

    all_tables.each_with_index do |table, tab_ind|
      next if tab_ind == 0
      # getting nearest h3 to stop the loop 
      h3_element = table.previous
      while h3_element&.name != "h3" && h3_element&.name != "body"
        h3_element = h3_element.previous
      end
      
      all_rows = table.css("tr")
      all_rows.each_with_index do |row, ind|
        next if ind < 2
        data_hash = {}
        data_hash["ex_team_name"] = h3_element.text.split(/\(\d+-\d+\)/).first
        data_hash["ex_road_team_name"] = row.css("td")[7].text
        data_hash["game_date"] = Date.parse(row.css("td")[0].text)
        data_hash["game_time"] = row.css("td")[1].text
        data_hash["data_source_url"] = CONFERENCES_URL_PREFIX + file_name.gsub("gz", "htm")
        data_hash = mark_empty_as_nil(data_hash)
        next if data_hash["game_time"] == "TBA" or data_hash["game_time"] == ""
        data_array.push(data_hash)
      end
    end
    data_array
  end

  private 

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

end
