
class DelawareVoterRegistrationsParser < Hamster::Parser
  MAIN_URL = "https://elections.delaware.gov"
  URL      = "https://elections.delaware.gov/services/candidate/"

  def get_pdf_link(main_page)
    pdf_array = []
    doc = Nokogiri::HTML(main_page.force_encoding("utf-8"))
    doc.css('div.divTableBody').css('div.divTableRow').each do |row|
      pdf_array << MAIN_URL+row.css('div.divTableCell')[3].css('a').first['href']
    end
    pdf_array
  end

  def get_data(doc, index, string)
    if string == 'Grand Total'
      if doc.select{|a| a.include? string}.second.to_s.split('  ').reject{|e| e.empty?}.count == 1
        data = doc[-3].to_s.split('  ').reject{|e| e.empty?}[index-1]
      else
        data = doc.select{|a| a.include? string}.second.to_s.split('  ').reject{|e| e.empty?}[index]
      end
    else
      data = doc.select{|a| a.include? string}.to_s.split('  ').reject{|e| e.empty?}[index]
      return nil if data.nil?
    end
    data.squish
  end

  def get_link_year(main_page)
    doc = Nokogiri::HTML(main_page.body.force_encoding("utf-8"))
    URL+doc.css("ul li a").select{|a| a.text.include? "Registered Voter Totals and By Political Party"}.first['href']
  end

  def get_pdf_data(path, runid, link)
    reader = PDF::Reader.new(path)
    document = reader.pages.first.text.scan(/^.+/)
    data_array = []
    (0..2).each do |index|
      data_hash = {} 
      data_hash[:run_id]          = runid
      data_hash[:month]           = document.first.squish.split(' ').second
      data_hash[:year]            = document.first.squish.split(' ').last
      data_hash[:county]          = document[6].split('  ').reject{|e| e.empty?}[index].squish
      data_hash[:amer_delta]      = get_data(document, index+1, "AMER DELTA")
      data_hash[:american]        = get_data(document, index+1, "AMERICAN")
      data_hash[:blue_enigima]    = get_data(document, index+1, "BLUE ENIGMA")
      data_hash[:conservative]    = get_data(document, index+1, "CONSERVATIVE")
      data_hash[:constitution]    = get_data(document, index+1, "CONSTITUTION")
      data_hash[:democratic]      = get_data(document, index+1, "DEMOCRATIC")
      data_hash[:green]           = get_data(document, index+1, "GREEN")
      data_hash[:ind_pty_of_de]   = get_data(document, index+1, "IND PTY OF DE")
      data_hash[:liberal]         = get_data(document, index+1, "LIBERAL")
      data_hash[:libertarian]     = get_data(document, index+1, "LIBERTARIAN")
      data_hash[:mandalorians]    = get_data(document, index+1, "MANDALORIANS")
      data_hash[:natural_law]     = get_data(document, index+1, "NATURAL LAW")
      data_hash[:no_party]        = get_data(document, index+1, "NO PARTY")
      data_hash[:nonpartisan]     = get_data(document, index+1, "ONPARTISAN")
      data_hash[:other]           = get_data(document, index+1, "OTHER")
      data_hash[:reform]          = get_data(document, index+1, "REFORM")
      data_hash[:republican]      = get_data(document, index+1, "REPUBLICAN")
      data_hash[:socialst_wr]     = get_data(document, index+1, "SOCIALST WR")
      data_hash[:working_fam]     = get_data(document, index+1, "WORKING FAM")
      data_hash[:grand_total]     = get_data(document, index+1, "Grand Total")
      data_hash[:data_source_url] = link
      data_hash[:last_scrape_date] = Date.today
      data_hash[:next_scrape_date] = Date.today.next_month
      data_array << data_hash
    end
    data_array
  end
end
