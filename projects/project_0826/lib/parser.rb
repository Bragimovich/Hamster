require_relative 'scraper'
require_relative 'manager'

class Parser < Hamster::Parser
  attr_reader :scraper

  def initialize
    super
    @scraper = Scraper.new
  end

  def get_detail_page(main_page)
    inmate_url = []
    doc = Nokogiri::HTML(main_page)
    base_url = "https://polkinmates.polkcountyiowa.gov"
    doc.xpath("//a[contains(text(), 'View')]").each do |link|
      inmate_url << base_url + link.xpath("@href").text
    end
    inmate_url
  end

  def parse_inmate_details(inmate, run_id)
    base_url = "https://polkinmates.polkcountyiowa.gov"
    source_url = "https://polkinmates.polkcountyiowa.gov/Inmates/Detail/"
    inmate_details = {}
    content = peon.give(file: inmate, subfolder: run_id)
    doc = Nokogiri::HTML(content)

    inmate_details[:full_name] = parse_text(doc, "Name")
    inmate_details[:last_name] = inmate_details[:full_name].split(",").first
    first_middle = inmate_details[:full_name].split(",").last
    inmate_details[:first_name] = first_middle.split.first rescue nil
    inmate_details[:middle_name] = nil

    inmate_details[:middle_name] = first_middle.split.last if first_middle.split.count > 1 rescue nil
    inmate_details[:race] = parse_text(doc, 'Race')
    inmate_details[:age] = parse_text(doc, 'Age')
    inmate_details[:sex] = parse_text(doc, 'Sex')
    inmate_details[:height] = parse_text(doc, 'Height').gsub('"', '')

    inmate_details[:weight] = parse_text(doc, 'Weight')
    inmate_details[:eye_color] = parse_text(doc, 'Eye Color')
    inmate_details[:hair_color] = parse_text(doc, 'Hair Color')
    inmate_details[:city] = parse_text(doc, 'City')
    inmate_details[:number] = parse_text(doc, 'Inmate Number')

    inmate_details[:booking_number] = parse_text(doc, 'Booking Number')
    inmate_details[:facility] = parse_text(doc, 'Holding Location')
    inmate_details[:charges] = parse_text(doc, 'Booking Date')
    image_url = doc.xpath("//img[@class='card-img-top']/@src").text
    inmate_details[:original_link] = base_url + doc.xpath("//img[@class='card-img-top']/@src").text

    key_start = "inmates/fl/polk/"
    aws_link = scraper.save_to_aws(image_url, key_start)
    inmate_details[:aws_link] = aws_link
    inmate_details[:data_source_url] = source_url + inmate.split('.').first
    generate_md5_hash(%i[full_name race age sex height weight hair_color city booking_number holding_location], inmate_details)
    inmate_details[:arrest_data] = get_arrest_data(doc, [inmate_details[:booking_number], inmate_details[:md5_hash], inmate_details[:data_source_url]])
    inmate_details
  end

  def parse_text(doc, element)
    doc.xpath("//th[text()='#{element}']/following-sibling::td").text
  end

  def get_arrest_data(doc, data_array)
    arrest_data = []
    booking_date = parse_text_doc(doc, 'Booking Date')
    arrest_agency = parse_text_doc(doc, 'Arrest Agency')
    charge_details = parse_text_doc(doc, 'Charge String')
    charge_counts = parse_text_doc(doc, 'Charge Count')
    case_number = parse_text_doc(doc, 'Case Number')
    case_date  = parse_text_doc(doc, 'Case Date')

    booking_date.zip(arrest_agency, charge_details, case_number, case_date, charge_counts).each do |booking, agency, details, case_numb, case_date, charge_count|
      arrest = {}
      arrest[:booking_date] = Date.strptime(booking.text.squish.split.first, "%m/%d/%Y").to_s
      arrest[:booking_agency] = agency.text.squish
      arrest[:description] = details.text.squish
      arrest[:number] = case_numb.text.squish
      arrest[:case_date] = Date.strptime(case_date.text.squish.split.first, "%m/%d/%Y").to_s
      arrest[:counts] = charge_count.text
      arrest[:booking_number] = data_array[0]
      arrest[:md5_hash] = data_array[1]
      arrest[:data_source_url] = data_array[2]
      arrest_data << arrest
    end
    arrest_data
  end

  def parse_text_doc(doc, element)
    doc.xpath("//th[text()='#{element}']/following-sibling::td")
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end
end
