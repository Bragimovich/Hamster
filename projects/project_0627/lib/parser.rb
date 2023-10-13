# frozen_string_literal: true
class Parser < Hamster::Parser

  def parse_html(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def get_values(main)
    event_validation = main.css("#__EVENTVALIDATION")[0]['value']
    view_state = main.css("#__VIEWSTATE")[0]['value']
    generator = main.css("#__VIEWSTATEGENERATOR")[0]['value']

    [event_validation, view_state, generator]
  end
  
  def get_contribution_data(file ,run_id, all_md5_hash)
    doc = File.read(file)
    all_data = CSV.parse(doc, :headers => true)
    hash_array = []
    all_data.each do |row|
      data_hash = {}
      data_hash[:filer_name]        = "#{row["FilerFirstName"]} #{row["FilerLastName"]}".strip
      data_hash[:report]            = "#{row["ReportCode"]} : #{row["ReportType"]} - #{row["ReportNumber"]}".strip
      data_hash[:report_link]       = "https://www.ethics.la.gov/CampaignFinanceSearch/ShowEForm.aspx?ReportID=#{row["ReportNumber"].split('-')[-1].strip}"
      data_hash[:type]              = row['ContributionType'].strip
      data_hash[:source_name]       = row['ContributorName'].strip
      data_hash[:source_complete_address] = "#{row['ContributorAddr1']} #{row['ContributorAddr2']} #{row["ContributorCity"]}, #{row["ContributorState"]} #{row['ContributorZip']}".strip

      data_hash[:description]       = row['ContributionDescription'].strip
      data_hash[:contribution_date] = DateTime.strptime(row['ContributionDate'].strip, "%m/%d/%Y").to_date rescue nil
      data_hash[:amount]            = row['ContributionAmt'].strip.gsub("$","").gsub(',','').gsub('(','').gsub(')','')

      next_blob, all_md5_hash = md5_comparison(all_md5_hash, data_hash)
      next if next_blob

      data_hash[:source_address]    = "#{row["ContributorAddr1"]} #{row["ContributorAddr2"]}".strip
      data_hash[:source_city]       = row['ContributorCity'].strip
      data_hash[:source_state]      = row['ContributorState'].strip
      data_hash[:source_zip]        = row['ContributorZip'].strip

      data_hash[:last_scrape_date]  = Date.today
      data_hash[:next_scrape_date]  = Date.today.next_day
      data_hash[:run_id]            = run_id
      data_hash = mark_empty_as_nil(data_hash)
      hash_array << data_hash
    end
    [hash_array, all_md5_hash]
  end

  def get_expenditure_data(file ,run_id, all_md5_hash)
    doc = File.read(file)
    all_data = CSV.parse(doc, :headers => true)
    hash_array = []
    all_data.each do |row|
      data_hash = {}

      data_hash[:filer_name]     = "#{row["FilerFirstName"]} #{row["FilerLastName"]}"
      data_hash[:report]         = "#{row["ReportCode"]} : #{row["ReportType"]} - #{row["ReportNumber"]}"
      data_hash[:report_link]    = "https://www.ethics.la.gov/CampaignFinanceSearch/ShowEForm.aspx?ReportID=#{row["ReportNumber"].split('-')[-1]}"
      data_hash[:recipient_name] = row['RecipientName']
      data_hash[:recipient_complete_address] = "#{row['RecipientAddr1']} #{row['RecipientAddr2']} #{row["RecipientCity"]}, #{row["RecipientState"]} #{row['RecipientZip']}".strip
      data_hash[:description]    = row['ExpenditureDescription'].strip
      data_hash[:filing_date]    = DateTime.strptime(row['ExpenditureDate'], "%m/%d/%Y").to_date rescue nil
      data_hash[:amount]         = row['ExpenditureAmt'].gsub("$","").gsub(',','').gsub('(','').gsub(')','')

      next_blob, all_md5_hash = md5_comparison(all_md5_hash, data_hash)
      next if next_blob

      data_hash[:recipient_address] = row['RecipientAddr1'].strip
      data_hash[:recipient_city]    = row["RecipientCity"]
      data_hash[:recipient_state]   = row["RecipientState"]
      data_hash[:recipient_zip]     = row['RecipientZip']

      data_hash[:last_scrape_date]  = Date.today
      data_hash[:next_scrape_date]  = Date.today.next_day
      data_hash[:run_id]         = run_id
      data_hash = mark_empty_as_nil(data_hash)
      hash_array << data_hash
    end
    [hash_array, all_md5_hash]
  end

  private

  def md5_comparison(all_md5_hash, data_hash)
    md5 = MD5Hash.new(:columns => data_hash.keys)
    hamster_md5 = md5.generate(data_hash)

    if all_md5_hash.keys.include? hamster_md5
      if all_md5_hash[hamster_md5] > 0
        all_md5_hash[hamster_md5] = all_md5_hash[hamster_md5] - 1
        return [true, all_md5_hash]
      end
    end
    [false, all_md5_hash]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value}
  end
end
