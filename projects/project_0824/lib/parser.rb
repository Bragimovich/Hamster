require 'date'
class Parser < Hamster::Parser
  SUBFOLDER = "Offender"
  
  def parse_html(response, letter)
    doc = Nokogiri::HTML response
    rows = doc.search('table > tr')
    column_names = rows.shift.css('th').map(&:text)
    offenderUrl = rows.map do |row|
      offenderID=row.css('td').map(&:text).first
      "https://www.nd.gov/docr/offenderlkup/offenderDetails.asp?offenderID=#{offenderID}"
    end
    offender_objects = []
    offenderUrl.each do |url|
      offender_data_hash = {}
      html_code = Net::HTTP.get(URI.parse(url))
      data = Nokogiri::HTML html_code
      data.css('table').each_with_index do |table, index_table|
        table.search('tr').each_with_index do |tr, index_tr|
          if index_tr == 0
            offender_data_hash[:full_name] = tr.children[3].text
          end

          if index_tr == 1
            offender_data_hash[:birthdate] = tr.children[3].text
          end

          if index_tr == 2
            offender_data_hash[:planned_release_date] = tr.children[3].text
          end

          if index_tr == 3
            offender_data_hash[:facility] = tr.children[3].text
          end

          if index_tr == 4
            offender_data_hash[:full_address] = tr.children[1].text
          end
        end
        offender_data_hash[:offender_id] = url.gsub("https://www.nd.gov/docr/offenderlkup/offenderDetails.asp?offenderID=","")
        offender_data_hash[:original_link] =  "https://www.nd.gov/docr/offenderlkup/images/"+offender_data_hash[:offender_id]+".jpg"
        offender_data_hash[:city] = offender_data_hash[:full_address].split(',').first.split(/\W+/).last(2).join(" ")
        offender_data_hash[:zip] =  offender_data_hash[:full_address].split(' ').last.gsub('ND','')
        offender_data_hash[:street_address] = offender_data_hash[:full_address]
        offender_data_hash[:full_address] = offender_data_hash[:facility]+" "+offender_data_hash[:full_address]
        offender_data_hash[:data_source_url] = url
        offender_objects << offender_data_hash
      end
      begin
        file_name = "#{letter.parameterize}.json"
        peon.put content: offender_objects.to_json, file: "#{file_name}", subfolder: SUBFOLDER
      rescue StandardError => e
        logger.debug e
        logger.debug e.backtrace
      end
    end
  end
end
