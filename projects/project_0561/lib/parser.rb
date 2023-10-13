require 'roo'

class Parser < Hamster::Harvester

  def initialize
    super
  end

  def parse_main_page(base_url, page_content)
    year_links = {}

    data = Nokogiri::HTML(page_content)
    filtered_data = data.xpath("//div[@class='rxbodyfield']")
    links = filtered_data.xpath("//h3")
    links.each do |link|
      filtered_links = link.next_element.css('a').select { |ele| ele.attributes["href"] and ele.attributes["href"].value.include?('.xlsx') }
      year_links[link.text.to_i] = filtered_links.map {|link_node|  
          "#{base_url}#{link_node.attributes["href"].value}"
        }
    end
    year_links
  end

  def get_spreadsheet(file_path)
    @logger.info "Parsing #{file_path}".yellow

    begin
      spreadsheet = Roo::Spreadsheet.open(file_path)
    rescue Ole::Storage::FormatError => error
      @logger.error e
      return []
    end
    spreadsheet
  end

  def parse_record(record)
    rec = record.map { |cell| cell ? cell.value : nil }
    {
      "state_fsa_code": rec[0],
      "state_fsa_name": rec[1],
      "county_fsa_code": rec[2],
      "county_fsa_name": rec[3],
      "formatted_payee_name": rec[4],
      "information_address": rec[5],
      "delivery_address": rec[6], 
      "city": rec[7],
      "state": rec[8],
      "zip": rec[9],
      "delivery_point_bar_code": rec[10],
      "disbursement_amount": rec[11],
      "payment_date": rec[12],
      "accounting_program_code": rec[13],
      "accounting_program_desc": rec[14], 
      "accounting_program_year": rec[15]
    }
  end

end
