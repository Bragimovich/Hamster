require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @profiles = []
  end

  def scrape
    download
    #store
  end

  def download
    inmate_id_counter = 1    
    ('a'..'z').each do |char|
      outer_pageurl = "https://denvergov.org/api/inmatelookup/odata/distinctbookings?$count=true&$orderby=used_person_last%20asc&$top=10&$skip=0&$filter=(contains(%27#{char}%27,used_person_last)%20or%20contains(%27#{char}%27,used_person_first)%20or%20contains(used_person_middle,%20%27#{char}%27)%20or%20contains(bookingno,%20%27#{char}%27)%20or%20contains(ethnicity,%20%27#{char}%27)%20or%20contains(inmate_number,%20%27#{char}%27))" 
      page_response, status = @scraper.download_main_page(outer_pageurl)
      arrests_hash, inmate_id_counter = @parser.denver_arrests(page_response.body,outer_pageurl,inmate_id_counter)
      @keeper.store_arrests(arrests_hash)
      inmate_id_counter2 = 1    
      inmateids_hash , inmate_id_counter2 = @parser.denver_inmateids(page_response.body,outer_pageurl,inmate_id_counter2)
      @keeper.store_inmateids(inmateids_hash)  
      @profiles << @parser.get_profiles(page_response.body)
      current_value = 0
      loop do      
        current_value += 10
          page_url = "https://denvergov.org/api/inmatelookup/odata/distinctbookings?$count=true&$orderby=used_person_last%20asc&$top=10&$skip=#{current_value}&$filter=(contains(%27#{char}%27,used_person_last)%20or%20contains(%27#{char}%27,used_person_first)%20or%20contains(used_person_middle,%20%27#{char}%27)%20or%20contains(bookingno,%20%27#{char}%27)%20or%20contains(ethnicity,%20%27#{char}%27)%20or%20contains(inmate_number,%20%27#{char}%27))" 
          page_response, status = @scraper.download_main_page(page_url)
          arrests_hash, inmate_id_counter = @parser.denver_arrests(page_response.body,page_url,inmate_id_counter)
          @keeper.store_arrests(arrests_hash) unless arrests_hash.empty?
          inmateids_hash , inmate_id_counter2 = @parser.denver_inmateids(page_response.body,page_url,inmate_id_counter2)
          @keeper.store_inmateids(inmateids_hash)  unless inmateids_hash.empty?
          @profiles << @parser.get_profiles(page_response.body)
        break if @parser.check_value?(page_response.body)
      end    
    end  
    profiles_value = @profiles.flatten
    get_inmate_detail(profiles_value)
  end

  def get_inmate_detail(profiles)  
    #profiles = profiles[0..50]
    inmate_id_counter = 1 
    inmate_id_counter2 = 1    
    profiles.each do |profile|
      profile_link = "https://denvergov.org/api/inmatelookup/odata/bookings?$count=true&$top=10&$skip=0&$filter=bookingno%20eq%20%27#{profile}%27"
      page_response, status = @scraper.download_main_page(profile_link)
      inmate_hash = @parser.get_inmates(page_response.body,profile_link)
      @keeper.store_inmates(inmate_hash)
      inmate_data, inmate_id_counter = @parser.get_inmate_addinfo(page_response.body,profile_link,inmate_id_counter)
      @keeper.store_inmates_addinfo(inmate_data)
      inmate_update, inmate_id_counter2 = @parser.denver_arrests_update(page_response.body,profile_link,inmate_id_counter2)
      @keeper.store_arrestsupdate(inmate_update)
      #p page_response.body
     end  
  end  

  def store
    # write store logic here
  end
end
