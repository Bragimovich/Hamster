require 'roo-xls'
class PennsylvaniaParser < Hamster::Parser
  
  def getting_data_of_files(path,run_id)
    final_data_array = []
    doc = Roo::Excel.new(path)
    sheet_name = doc.default_sheet = doc.sheets[0]
    date =  doc.select{|ele| ele.first.include? 'Information'}.first.first.split.last
    doc.sheet(sheet_name).each do |row|
      data_hash = {}
      data_hash[:county] = row[0]
      next if data_hash[:county].include? 'County' or data_hash[:county].include? 'Information'

      break if data_hash[:county]                   == 'Totals:'
      data_hash[:source_date]                       = date
      data_hash[:year]                              = date.split("/")[-1]
      data_hash[:day]                               = date.split("/")[1]
      data_hash[:month]                             = date.split("/")[0]
      data_hash[:pl_gather_task_id]                 = '8691'
      data_hash[:run_id]                            = run_id
      data_hash[:id_number]                         = row[1] 
      data_hash[:count_of_democratic_voters]        = row[2]
      data_hash[:count_of_republican_voters]        = row[4]
      data_hash[:count_of_no_affiliation_voters]    = row[6]
      data_hash[:count_of_all_others_voters]        = row[8]
      data_hash[:total_count_of_all_voters]         = row[10]
      data_hash[:data_source_url]                   = 'https://www.dos.pa.gov/VotingElections/OtherServicesEvents/VotingElectionStatistics/Pages/VotingElectionStatistics.aspx'
      data_hash[:dataset_name_prefix]               = 'pennsylvania_voter_registrations'
      data_hash[:last_scrape_date]                  = Date.today
      data_hash[:next_scrape_date]                  = Date.tomorrow
      final_data_array.append(data_hash)
    end
    final_data_array
  end

  def getting_files_link(response)
     domain = 'https://www.dos.pa.gov'
     page = Nokogiri::HTML(response.body.force_encoding('utf-8'))
     domain + page.css('div#ctl00_PlaceHolderMain_PageContent__ControlWrapper_RichHtmlField').css('ul')[0].css('li')[0].css('a')[0][:href]
  end
end
