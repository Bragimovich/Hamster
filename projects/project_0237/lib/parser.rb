
class IowaParser < Hamster::Parser
  
  def getting_data_of_files(path,run_id)
    final_data_array = []
    begin
      pdf_reader = PDF::Reader.new(open(path)) 
    rescue StandardError => e
      puts e
    end
    if pdf_reader != nil
      document  = pdf_reader.pages.first.text.scan(/^.+/)
      date = document.select{|ele| ele.include? 'State of Iowa Voter Registration Totals'}.first.split.last
      pdf_reader.pages.each_with_index do |page, index|
        next if index == 0
        document = document + page.text.scan(/^.+/)
      end
      document.each do |row|
        data_hash ={}
        data_hash[:county] = get_values(row, 0)
        next if (data_hash[:county].include? 'State') || (data_hash[:county].include? 'County') || (data_hash[:county].include? 'Democratic') || (data_hash[:county].include? 'Prepared')
        
        break if data_hash[:county]       == 'Totals'
        data_hash[:source_date]           = date
        data_hash[:year]                  = date.split("/")[-1]
        data_hash[:day]                   = date.split("/")[1]
        data_hash[:month]                 = date.split("/")[0]
        data_hash[:run_id]                = run_id
        data_hash[:democratic_active]     = get_values(row, 1)
        data_hash[:republican_active]     = get_values(row, 2)
        data_hash[:no_party_active]       = get_values(row, 3)
        data_hash[:other_active]          = get_values(row, 4)
        data_hash[:total_active]          = get_values(row, 5)
        data_hash[:democratic_inactive]   = get_values(row, 6)
        data_hash[:republican_inactive]   = get_values(row, 7)
        data_hash[:no_party_inactive]     = get_values(row, 8)
        data_hash[:other_inactive]        = get_values(row, 9)
        data_hash[:total_inactive]        = get_values(row, 10)
        data_hash[:grand_total]           = get_values(row, 11)
        data_hash[:data_source_url]       = 'https://sos.iowa.gov/elections/voterreg/county.html'
        data_hash[:last_scrape_date]      = Date.today
        data_hash[:next_scrape_date]      = Date.tomorrow
        data_hash[:pl_gather_task_id]     = '8722'
        data_hash[:dataset_name_prefix]   = 'iowa_voter_registrations'
        final_data_array.append(data_hash)
      end
    end
    final_data_array
  end

  def getting_files_link(response,year)
    pdf_links_array = []
    domain = 'https://sos.iowa.gov'
    page = Nokogiri::HTML(response.body.force_encoding('utf-8'))
    page.at("a[name = #{year}]").next_element.next_element.css('a').each {|e| pdf_links_array << domain + e['href']}
    pdf_links_array unless pdf_links_array.empty?
  end

  private

  def get_values(row, index)
    row.split('  ').reject{|e| e.empty?}[index].strip
  end
  
end
