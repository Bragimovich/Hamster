# frozen_string_literal: true
class Parser <  Hamster::Scraper

  def get_token(response)
    parse_page(response).css("form.well").children.last.values[-1]
  end

  def parse(response, run_id)
    page = parse_page(response).css("div.col-sm-9 .well")
    data_hash = {}
    data_hash[:first_name]      = page[1].css("strong")[0].text rescue nil
    data_hash[:last_name]       = page[1].css("strong")[1].text rescue nil
    data_hash[:full_name]       = parse_page(response).css("h2").text.squish
    data_hash[:middle_name]     = data_hash[:full_name].split.last if (data_hash[:full_name].split(" ").last).length < 2
    data_hash[:age]             = page[1].css("strong")[2].text.squish rescue nil
    data_hash[:age_as_of_date]  = page[1].css("strong")[2].text.squish rescue nil
    data_hash[:sex]             = page[1].css("strong")[3].text.squish rescue nil
    data_hash.update(additional_columns(data_hash, run_id))
    data_hash
  end

  def parse_image(response, arrestee_id, booking_number, run_id)
    page = parse_page(response)
    data_hash = {}
    data_hash[:arrestee_id]    = arrestee_id
    data_hash[:original_link]  = "https://iic.ccsheriff.org" + page.css("div.row .col-sm-3 img")[0]["src"].squish
    file_name                  = page.css("div.row .col-sm-3 img")[0]["src"].squish.split("/").last
    key                        = "crime_perps_mugshots/il/cook/#{booking_number.to_s}.png"
    data_hash[:aws_link]       = key
    data_hash.update(additional_columns(data_hash, run_id))
    data_hash
  end

  def parse_arrestes(response, arrestee_id, run_id)
    page = parse_page(response).css("div.col-sm-9 .well")
    data_hash = {}
    data_hash[:arrestee_id]    = arrestee_id
    data_hash[:booking_date]   = Date.strptime(page[2].css("strong")[0].text.squish,"%m/%d/%Y")
    data_hash[:booking_number] = page[2].css("strong")[1].text.squish
    data_hash[:status]         = "In custody"
    data_hash.update(additional_columns(data_hash, run_id))
    data_hash
  end

  def parse_facility(response, arrest_id, run_id)
    page = parse_page(response).css("div.col-sm-9 .well")
    data_hash = {}
    data_hash[:arrest_id] = arrest_id
    data_hash[:facility]  = page[2].css("strong")[2].text.squish rescue nil
    data_hash.update(additional_columns(data_hash, run_id))
    data_hash
  end

  def parse_bond(response, arrest_id, run_id, iteration, hearing_id)
    page = parse_page(response).css("div.col-sm-9 .well")
    amount = page[iteration].css("strong")[2].text.squish.gsub(",","")
    return nil if amount =="*NO BOND*"    
    data_hash = {}
    data_hash[:arrest_id]     = arrest_id
    data_hash[:hearing_id]    = hearing_id
    data_hash[:bond_amount]   = page[iteration].css("strong")[2].text.squish.gsub(",","").to_i rescue nil
    data_hash[:bond_category] = "Surety Bond"
    data_hash.update(additional_columns(data_hash, run_id))
    data_hash
  end

  def parse_court(response, arrest_id, run_id, iteration)
    page = parse_page(response).css("div.col-sm-9 .well")
    data_hash = {}
    data_hash[:arrest_id]      = arrest_id
    data_hash[:court_date]     = Date.strptime(page[iteration].css("strong")[0].text.squish,"%m/%d/%Y") rescue nil
    data_hash[:court_location] = page[iteration].css("strong")[1].text.squish
    data_hash.update(additional_columns(data_hash, run_id))
    data_hash
  end

  def court_count(response)
    parse_page(response).css("div.col-sm-9 .well").count
  end

  private

  def additional_columns(case_information, run_id)
    case_info = {}
    case_info[:md5_hash]          = create_md5_hash(case_information)
    case_info[:data_source_url]   = "https://iic.ccsheriff.org/InmateLocator/Details"
    case_info[:run_id]            = run_id
    case_info[:touched_run_id]    = run_id
    case_info
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end
end
