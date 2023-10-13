# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  FRANK_RAO = 'U04MHBRVB6F'
  URL = "https://claremont.shinyapps.io/BLM_Funding/"

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end
  
  def download_and_store_general
    Hamster.report(to: FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload and Store", use: :slack)
    scraper = Scraper.new
    scraper.landing_page(URL)
    items = scraper.get_all_data
    @keeper.store_data(items, BlmFunding)
    scraper.close_browser
  end
  
  def store_recipients_and_locations
    scraper = Scraper.new
    scraper.landing_page(URL)
    
    recipient_items = scraper.get_recipient_dropdown_items
    location_items = scraper.get_location_dropdown_items
    prev_id = nil
    recipient_items.each_with_index do |recipient_item, index|
      begin
        scraper.dropdown_change_with(recipient_item[:id], prev_id)
        prev_id = recipient_item[:id]
        contributor_items = scraper.get_all_data
        contributor_items.each do |item|
          @keeper.update_recipient(item[:contributor], recipient_item[:value])
        end
      rescue Exception => e
        Hamster.report(to: FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
      # break if index > 0
    end
    location_items.each_with_index do |location_item, index|
      begin
        scraper.dropdown_change_with(location_item[:id], prev_id)
        prev_id = location_item[:id]
        contributor_items = scraper.get_all_data
        contributor_items.each do |item|
          @keeper.update_location(item[:contributor], location_item[:value])
        end
      rescue Exception => e
        Hamster.report(to: FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
    end
    scraper.close_browser
  end

  def store_recipients

    scraper = Scraper.new
    scraper.landing_page(URL)
    
    recipient_items = scraper.get_recipient_dropdown_items
    location_items = scraper.get_location_dropdown_items
    prev_id = nil
    recipient_items.each_with_index do |recipient_item, index|
      begin
        scraper.dropdown_change_with(recipient_item[:id], prev_id)
        prev_id = recipient_item[:id]
        contributor_items = scraper.get_all_data
        contributor_items.each do |item|
          @keeper.add_recipient(item[:contributor], recipient_item[:value])
        end
      rescue Exception => e
        Hamster.report(to: FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
    end
    
    scraper.close_browser
  end

  def store_hq_locations

    scraper = Scraper.new
    scraper.landing_page(URL)
    
    # recipient_items = scraper.get_recipient_dropdown_items
    location_items = scraper.get_location_dropdown_items
    prev_id = nil
    location_items.each_with_index do |location_item, index|
      begin
        scraper.dropdown_change_with(location_item[:id], prev_id)
        prev_id = location_item[:id]
        contributor_items = scraper.get_all_data
        contributor_items.each do |item|
          @keeper.add_hq_location(item[:contributor], location_item[:value])
        end
      rescue Exception => e
        Hamster.report(to: FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
    end
    
    scraper.close_browser
  end

  def store_details
    scraper = Scraper.new
    scraper.landing_page(URL)
    contributor_items = scraper.get_all_data
    contributor_items.each_with_index do |contributor_item, index|
      begin
        scraper.show_detail(index)
        @keeper.update_detail(contributor_item[:contributor], scraper.get_detail)
        scraper.hide_detail(index)
      rescue Exception => e
        Hamster.report(to: FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
    end
    scraper.close_browser
  end

  def store_gather_date
    scraper = Scraper.new
    scraper.landing_page(URL)
    contributor_items = scraper.get_all_data
    contributor_items.each_with_index do |contributor_item, index|
      begin
        @keeper.update_gather_date(contributor_item[:contributor])
      rescue Exception => e
        Hamster.report(to: FRANK_RAO, message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
    end
    scraper.close_browser
  end

  def update_md5_hash
    @keeper.update_md5_hash
  end

  def change_amount_to_int
    @keeper.change_amount_to_int
  end
  
end
