# frozen_string_literal: true


TITLE_ANALOGUE = {"License #"=>:license_number, "License Type"=> :license_type,  "Status"=>:status,
                  "Expiration Date"=>:expiration_date, "City"=>:city, "State"=>:state, "Zip"=>:zip, "County"=>:county}

def parse_main_page(html='')
  #html = File.open('projects/project_0106/lib/test/main_page2.html').read

  doc = Nokogiri::HTML(html)

  last_page=0
  last_page=1 if doc.css('.pagination').css('.last')[0].attr('class').split(' ')[-1]=='disabled'
  license_holders_array = Array.new()
  #p doc.css('.pagination')[0].to_s
  holders_nokogiri = doc.css(".record-fluid")

  holders_nokogiri.each do |holder|

    # ____BROKER name and alternate Broker name___
    head = holder.css(".panel-heading")[0]
    link_nkgr = head.css("a")[0]
    broker_name = link_nkgr.content
    link = "https://www.trec.texas.gov/apps/license-holder-search/" + link_nkgr["href"]
    if head.css('small')[0]
      alternate_name_data = head.css('small')[0].content
      alternate_names = alternate_name_data.split(":")[1].gsub(/\)|\(/, "").split('", ')
      alternate_names.map! {|name| name.gsub("\"", "").strip}
    end

    # ___License type information___
    holder.css('.panel-body').css(".row").each do |license|
      license_holders_array.push({holder_name:broker_name, link: link})
      license_holders_array[-1][:alternate_name] = alternate_names if alternate_names
      license.css('.field-fluid').each do |column|
        column_label = column.css(".label-fluid")[0].content
        column_data = column.css(".data-fluid")[0].content
        license_holders_array[-1][TITLE_ANALOGUE[column_label]] = column_data
      end
    end
  end
  return license_holders_array, last_page
end

TITLE_SPONSORS_ANALOGUE = {
  "name"=> :name, "Name"=>:name, "Sponsor Date"=> :sponsor_date, "Effective Date"=> :sponsor_date, "License #"=> :license_number,
  "License Type"=> :license_type, "Expiration Date" =>:expiration_date, "Business Address" => :business_address,
  "Name (License Type)" => :name_lic_type,
}

def parse_broker_page(html='')
  #html = File.open('projects/project_0106/lib/test/broker_page.html').read
  doc = Nokogiri::HTML(html)
  sponsors = Array.new()
  doc.css('.record-fluid').each do |body|

    body.css('.row').each do |row|
      if row.css('.license-sponsor')[0]

        sponsors.push({})

        sponsors[-1][:holder_lic_number] = body.css('.panel-title')[0].content.split('#')[-1].to_i
        sponsors[-1][:role] = row.css('.license-sponsor')[0].css('h4')[0].content.split(' ')[1]


        row.css('.field-fluid').each do |field|
          column_label = field.css(".label-fluid")[0].content

          if column_label=="Name (License Type)"
            break if sponsors[-1][:name_lic_type]
            link = "https://www.trec.texas.gov/apps/license-holder-search/" + field.css(".data-fluid").css('a')[0]['href']
            sponsors[-1][:business_address] = parse_business_address(link)
          end

          column_data  = field.css(".data-fluid")[0].content
          column_data  = field.css(".data-fluid")[0].to_s.gsub("<br>", "\n\n").gsub(/\<(\/?[^>]+)>/, '').strip if column_label=="Business Address"
          sponsors[-1][TITLE_SPONSORS_ANALOGUE[column_label]] = column_data

        end

        if sponsors[-1][:business_address]
          sponsors[-1][:business_city_state_zip] = sponsors[-1][:business_address].split("\n")[-1]
          sponsors[-1][:business_address] = sponsors[-1][:business_address].split("\n")[0]
        end

        if sponsors[-1][:name_lic_type]
          name_lic_type = sponsors[-1][:name_lic_type].gsub(")","").split("(")
          sponsors[-1][:name] = name_lic_type[0].strip
          sponsors[-1][:license_type] = name_lic_type[1].strip
        end

      end
    end
  end
  sponsors
end

def parse_business_address(link)
  html_page = connect_to(link).body
  doc = Nokogiri::HTML(html_page)
  # doc.xpath("/html/body/div/section[4]/div/div[1]/div[2]/div[1]/div/div[2]/div[2]/div/div[2]")
  #    .to_s.gsub("<br>", "\n\n").gsub(/\<(\/?[^>]+)>/, '').strip
  column_data=''
  doc.css(".field-fluid").each do |field|
    if field.css(".label-fluid")[0].content=="Business Address"
      column_data  = field.css(".data-fluid")[0].to_s.gsub("<br>", "\n\n").gsub(/\<(\/?[^>]+)>/, '').strip
      break
    end
  end
  column_data
end