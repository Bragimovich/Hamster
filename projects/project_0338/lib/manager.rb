# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester
  DOWNLOAD_URL = 'https://cfb.mn.gov/reports-and-data/self-help/data-downloads/campaign-finance'
  CONTRIBUTIONS_WEBSITE = 'Contributions received by all entities - 2015 to present'
  CONTRIBUTIONS_CSV_NAME = Date.today.strftime('%Y-%m-%d_contributions.csv')
  EXPENDITURES_CSV_NAME = Date.today.strftime('%Y-%m-%d_expenditures.csv')
  EXPENDITURES_WEBSITE = 'Expenditures, including contributions made,  by all entities - 2015 to present'
  TABS_ARRAY = ['information', 'officers']
  CSV_TYPES = [
    {'type' => 'expenditures', 'website' => EXPENDITURES_WEBSITE, 'file_name' => EXPENDITURES_CSV_NAME},
    {'type' => 'contributions', 'website' => CONTRIBUTIONS_WEBSITE, 'file_name' => CONTRIBUTIONS_CSV_NAME}
  ]

  def initialize(**params)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = keeper.run_id
  end

  def main
    scrape_candidates
    scrape_committees
    scrape_parties
    scrape_csv_files
  end
  
  private 
  attr_accessor :keeper, :scraper, :parser, :run_id

  def scrape_candidates
   logger.info cookie = scraper.get_cookie
    response = scraper.search_items_list_get_request(cookie, 'candidate')
    candidates_data = parser.parse_json(response.body)
    registered_entity_id = nil
    candidate_json = nil
    contact_response = nil
    md5_hash_array = []    
    (2015..Date.today.year).to_a.reverse.each do |year|
      candidates_data.each do |item|
       logger.info item.first
        candidate = scraper.candidate_post_request(item.first, year, cookie, 'information')
        contact = scraper.candidate_post_request(item.first, year, cookie, 'officers')
        next if candidate.body.include?('No information found for Information') || contact.body.include?('No information found for Contacts')
        candidate_json = parser.parse_json(candidate.body)
        contact_response = contact.body
        registered_entity_id = candidate_json.first['RegisteredEntityID']
        candidate_hash = parser.parse_candidate(candidate_json, year, contact_response, registered_entity_id, run_id)
        md5 = candidate_hash["md5_hash"]
        md5_hash_array.push(md5)
        keeper.insert_data_candidate(candidate_hash) if keeper.save_candidate?(candidate_hash)
        logger.info "=========== CANDIDATES HASH ============"
      end
    end
    md5_hash_array 
    keeper.update_touch_run_id(md5_hash_array, "candidate")
    keeper.mark_as_deleted(md5_hash_array, "candidate")
  end

  def scrape_committees
   logger.info cookie = scraper.get_cookie
    response = scraper.search_items_list_get_request(cookie, 'pcf')
    committees_data = parser.parse_json(response.body)
    md5_hash_array = [] 
    (2015..Date.today.year).to_a.reverse.each do |year|
      committees_data.each do |item|
       logger.info item.first
        response = scraper.committee_post_request(item.first, year, cookie)
        next if response.body.include?('No information found for Information')
        committee_json = parser.parse_json(response.body)
        data_hash = parser.parse_committee(committee_json, year, run_id)
        md5 = data_hash["md5_hash"]
        md5_hash_array.push(md5)
        keeper.insert_data_committee(data_hash)
        logger.info "=========== COMMITTEE HASH ============"
      end
    end
    md5_hash_array 
    keeper.update_touch_run_id(md5_hash_array, "pcf")
    keeper.mark_as_deleted(md5_hash_array, "pcf")
  end

  def scrape_parties
   logger.info cookie = scraper.get_cookie
    response = scraper.search_items_list_get_request(cookie, 'party')
    parties_data = parser.parse_json(response.body)
    md5_hash_array = [] 
    (2015..Date.today.year).to_a.reverse.each do |year|
      parties_data.each do |item|
       logger.info item.first
        response = scraper.party_post_request(item.first, year, cookie)
        next if response.body.include?('No information found for Information')
        party_json = parser.parse_json(response.body)
        data_hash = parser.parse_party(party_json, year, run_id)
        md5 = data_hash["md5_hash"]
        md5_hash_array.push(md5)
        keeper.insert_data_party(data_hash)
        logger.info "=========== PARTY HASH ============"
      end
    end
    md5_hash_array 
    keeper.update_touch_run_id(md5_hash_array, "party")
    keeper.mark_as_deleted(md5_hash_array, "party")    
  end

  def scrape_csv_files
    FileUtils.rm Dir["#{storehouse}/store/*.csv"]
    CSV_TYPES.each do |csv|
      logger.info "=================== >>> #{csv['type']} <<< ==================="
      cookie = scraper.get_cookie
      response = scraper.search_items_list_get_request(cookie, 'csv')
      csv_url = parser.csv_url_parser(response.body, csv['website'])
      file_url = "#{DOWNLOAD_URL}#{csv_url}"
      # Check File to end for dates
      file_path = "#{storehouse}store/#{csv['file_name']}"
      scraper.download_csv_file(file_url, file_path)
      keeper.load_tmp_csv(file_path, csv['type'])
      update_csv(csv['type'])
      keeper.validate_result(csv['type'])
    end
    keeper.finish
  end
  
  def update_csv(csv_type)
    keeper.generate_md5_on_temp_csv_table(csv_type)
    keeper.clear_csv_touched(csv_type)
    2015.upto(Time.now.year).each do |year|
      1.upto(12).each do |month|
        start_date = Date.new(year, month, 1).strftime('%Y-%m-%d')
        end_date = Date.new(year, month, -1).strftime('%Y-%m-%d')
        keeper.set_csv_touched(start_date, end_date, csv_type)
      end
    end
    keeper.set_csv_deleted(csv_type)
    keeper.copy_new_csv(csv_type)
  end

end
