# frozen_string_literal: true

class Parser < Hamster::Parser

  attr_reader :charges

  def self.parse_post_request(html)
    req_hash = {}
    doc = Nokogiri::HTML(html)

    doc.css('input').each do |input|
      if input['name'].include?('ctl00$Content')
        next #if !good_ctl00content.include?(input['name'])
      end
      req_hash[input['name']]=input['value']
    end
    req_hash['ctl00$Content$btnCustody']=''
    req_hash
  end


  def general_page(source)
    page = Nokogiri::HTML source

    @persons_general = {}

    page.css('tr')[1..].each do |tr|
      link = tr.css('a')[0]
      booking_id= link['href'].split('=')[-1]
      @persons_general[booking_id] =
        {
          name: link.content,
          link: 'https://kaneapplications.countyofkane.org/DETAINEESEARCH/' + link['href'],
          booked_date: Date.strptime(tr.css('td')[1].content,'%m/%d/%Y '),
        }
    end
    @persons_general
  end

  def facility(source)
    page = Nokogiri::HTML source
    page.css('span#lblFacility')[0].content
  end

  CHARGES_CHANGING_NAME = {
    'Release Date:' => :actual_release_date,
    'Bail Amount:' => :bond_amount,
    'Reason for Release:' => :reason_release,
    'Next Court Date:' => :court_date,
    'Court Location:' => :court_name,
    'Custody Status:' => :status,
    'Anticipated Release Date:' => :planned_release_date,
  }

  def all_charges(booking_id, html)
    page = Nokogiri::HTML html
    charges_nokogiri = page.css('table#dgCharges')
    court_name = page.css('#Label1')[0].content.strip
    @charges = []
    charges_nokogiri.css('tr').each do |tr|

      label_name = tr.css('td')[0].content.strip
      value = tr.css('td')[1].content.strip
      value = nil if value.in?([" ", '', " "])

      if label_name=='Charge:'
        @charges.push({
                       description: value,
                       data_source_url: @persons_general[booking_id][:link],
                       court_name: court_name
                     })
      end
      if CHARGES_CHANGING_NAME.keys.include?(label_name)
        @charges[-1][CHARGES_CHANGING_NAME[label_name]] = value if !value.nil?
      end

    end
    @charges.push({
                    bond_amount: page.css('span#lblTotalBail')[0].content,
                    bond_category: "Total Bail",
                    data_source_url: @persons_general[booking_id][:link]
                  })
    @charges
  end

  def arrestees(booking_id, html)
    page = Nokogiri::HTML html
    arreste = {}
    arreste[:mugshot] = page.css('img#imgInmate')[0]['src']
    arreste[:id] = page.css('span#lblInmateNumber')[0].content
    arreste[:full_name] = page.css('span#lblName')[0].content
    arreste[:age] = page.css('span#lblAge')[0].content
    arreste[:sex] = page.css('span#lblSex')[0].content
    arreste[:data_source_url] = @persons_general[booking_id][:link]
    arreste
  end


  def address(booking_id, html)
    page = Nokogiri::HTML html
    full_address = page.css('#Label2')[0].content.strip
    splitted_full_address = full_address.split(',').map!{|q| q.strip}
    address = {
      full_address: full_address,
      zip: splitted_full_address[-1],
      state: splitted_full_address[-2],
      city: splitted_full_address[-3],
      data_source_url: @persons_general[booking_id][:link],
    }
    address
  end

  def arrest(booking_id, html)
    page = Nokogiri::HTML html
    arrest = {}

    arrest[:arrest_date] = Date.strptime(page.css('span#lblBookingDtTime')[0].content,'%m/%d/%Y ')
    arrest[:booking_date] = @persons_general[booking_id][:booked_date]
    arrest[:booking_agency] = page.css('span#lblArrestAgency')[0].content
    arrest[:booking_number] = booking_id
    @charges.each do |ch|
      next if ch[:status].nil?
      if ch[:status].strip!=''
        arrest[:status] = ch[:status]
        break
      end
    end
    arrest[:data_source_url] = @persons_general[booking_id][:link]

    arrest
  end

  def holding_activity(booking_id, html)
    page = Nokogiri::HTML html

    ha = {}
    ha[:facility] = page.css('span#lblFacility')[0].content
    ha[:start_date] = Date.strptime(page.css('span#lblBookingDtTime')[0].content,'%m/%d/%Y ')
    ha[:data_source_url] = @persons_general[booking_id][:link]
    ha
  end
end