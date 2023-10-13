# frozen_string_literal: true

class Parser < Hamster::Parser

  def initialize(**params)
    super
    @keeper = Keeper.new
  end

  def parse_html(body)
    Nokogiri::HTML(body)
  end

  def get_pdf_links(page)
    data_array = []
    all_panels = page.css(".panels-list .panels-list-item")
    all_panels.each do |panel|
      panel_title = panel.css(".views-field .field-content .panel-item .panel-item-title").text.strip
      next unless panel_title.include?("Annual Salary Disclosure Report")
      panel_body = panel.css(".views-field .field-content .panel-item .panel-item-body")
      all_links = panel_body.css("ul li a")
      all_links.each do |link|
        data_hash = {}
        data_hash["title"] = link.text.strip
        data_hash["link"] = link["href"]
        data_array.push(data_hash)
      end
    end
    data_array
  end

  def pdf_data_parser(pdf_pages, run_id)
    data_array = []
    pdf_pages.each_with_index do |page, ind|
      next if ind == 0
      page_in_txt = page.text
      data_rows = page_in_txt.split("FUND\n").last.split("\n").reject{|e| e.empty? }
      data_rows.each do |row|
        data_hash = {}
        data_hash["ex_page_num"] = page_in_txt.split(/Page.No:./).last.split(/.of/).first.strip
        dates = page_in_txt.scan(/\b\d{1,2}\/\d{1,2}\/\d{4}\b/)
        data_hash["as_of_date"] = Date.strptime(dates[0],"%m/%d/%Y").to_date.to_s 
        data_hash["destribution_date"] = Date.strptime(dates[1],"%m/%d/%Y").to_date.to_s
        org_row = row
        if row.split(/\s{1,}/).count == 9
          row = row.split(/\s{1,}/)
          row.insert(2, row[2]+row[3])
          row.delete_at(3)
          row.delete_at(3)
        elsif row.split(/\s{2,}/).count == 8 
          row = row.split(/\s{2,}/)
        elsif row.split(/\s{1,}/).count == 8
          row = row.split(/\s{1,}/)
        end
        data_hash["campus"] = row[0].strip.gsub("‐","-")
        data_hash["name"] = row[1].strip.gsub("‐","-")
        data_hash["appointment_title"] = row[2].strip.gsub("‐","-")
        data_hash["appointment_dep"] = row[3].strip.gsub("‐","-")
        data_hash["appt_annual_ftr"] = row[4].strip.gsub(",","")
        data_hash["appt_ftr_basis"] = row[5].strip.gsub("‐","-")
        data_hash["appt_fraction"] = row[6].strip.gsub(",","")
        data_hash["amt_of_salary_paid_from_genl_fund"] = row[7].strip.gsub(",","")
        data_hash = mark_empty_as_nil(data_hash)
        data_hash["md5_hash"] = create_md5_hash(data_hash)
        data_hash["run_id"] = run_id
        data_hash["touched_run_id"] = run_id
        data_array.push(data_hash)
      end
    end
    data_array
  end

  private

  attr_accessor :keeper

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end
  
end
