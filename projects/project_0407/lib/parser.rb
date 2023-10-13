require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def parse_view_state(hamster)
    view_state = Nokogiri::HTML.parse(hamster.body).css('#__VIEWSTATE')[0]['value'].to_s
    view_state = view_state.gsub('/','%2F').gsub('+','%2B').gsub('=','%3D')
    view_state_gen = Nokogiri::HTML.parse(hamster.body).css('#__VIEWSTATEGENERATOR')[0]['value'].to_s
    [view_state, view_state_gen]
  end

  def parse_table_info(hamster, page)
    table = Nokogiri::HTML.parse(hamster.body).css('#ctl04_gvDecisions')
    page_nums = table.css('.pagenation')[0].css('table td')
    page_nums_arr = []
    page_nums.each do |page_num|
      page_nums_arr << page_num.text.to_s
    end
    table_info = []
    if page_nums_arr.include? page.to_s
      logger.info "Find page ##{page}!".blue
      table.css('.pagenation').remove
      table.css('tr')[0].remove
      rows = table.css('tr')
      rows.each do |row|
        case_name = row.css('td')[0].text.to_s.strip
        citation = row.css('td')[1].text.to_s.strip
        next if citation.blank?
        case_id = citation.gsub(/\s/, ' ').squeeze(' ').split(' ')[-1].strip
        link = row.css('td')[0]
        link = link.css('a')
        link = link[0]['href'] unless link.blank?
        link = 'https://www.illinoiscourts.gov' + link unless link.blank?
        link = nil if link.blank?
        filing_date = row.css('td')[2].text.to_s.strip
        filing_date = Date.strptime(filing_date, '%m/%d/%Y') unless filing_date.blank?
        court = row.css('td')[3].text.to_s.strip
        decision_type = row.css('td')[4].text.to_s.strip
        status = row.css('td')[5].text.to_s.strip
        notes = row.css('td')[6].text.to_s.strip
        table_info << {
          file_name: nil,
          link_original: nil,
          link: link,
          case_name: case_name,
          citation: citation,
          case_id: case_id,
          filing_date: filing_date,
          court: court,
          decision_type: decision_type,
          status: status,
          notes: notes
        }
      end
    else
      nil
    end
    table_info
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
    message_send(message)
  end

  def info_parse(page, pdf_path, court_id)
    body = Nokogiri::HTML.parse(page)
    file_name = body.css('.file_name').text.to_s.strip
    file_name = nil if file_name.blank?
    link = body.css('.link').text.to_s.strip
    link = nil if link.blank?
    case_name = body.css('.case_name').text.to_s.strip
    case_name = nil if case_name.blank?
    case_id = body.css('.case_id').text.to_s.strip
    case_id = nil if case_id.blank?
    filing_date = body.css('.filing_date').text.to_s.strip
    filing_date = nil if filing_date.blank?
    decision_type = body.css('.decision_type').text.to_s.strip
    decision_type = nil if decision_type.blank?
    status = body.css('.status').text.to_s.strip
    status = nil if status.blank?
    notes = body.css('.notes').text.to_s.strip
    notes = nil if notes.blank?
    lower_case_id = nil
    parties = []
    lower_judge_name = nil
    lower_court_name = nil
    unless file_name.blank?
      reader = PDF::Reader.new("/home/hamster/HarvestStorehouse/project_0407/trash/#{pdf_path}/#{file_name}")
      page = reader.pages.map(&:text).join("\n")
      unless page.blank?
        if decision_type == 'Opinion'
          page = page.gsub(/OPINION(\s+.+)+/,'')
          check_row = page.gsub("\n",' ').squeeze(' ').strip
          if check_row.match?(/^[\\]?Illinois Official Reports/)
            rows = page.split(/\n\n\n/).reject(&:blank?)
            text = page.squeeze("\n").squeeze(' ').strip
            check_court = rows[1].strip.downcase
            if check_court.include? 'supreme'
              row_case_name = text.gsub(/^(.|\n)+\n(\s+)?Caption in Supreme/, '').gsub("Court:",' ').gsub(/Docket No(s)?\.(.|\s)+/, '').gsub("\n",' ').squeeze(' ').strip
              parties = parties(row_case_name, court_id, case_id)
            elsif check_court.include? 'appellate'
              row_case_name = text.gsub(/^(.|\n)+\n(\s+)?Appellate Court/, '').gsub("Caption",' ').gsub(/District & No(s)?\.(.|\s)+/, '').gsub("\n",' ').squeeze(' ').strip
              parties = parties(row_case_name, court_id, case_id)
            end
          elsif check_row.match?(/\(Docket No(s)?\. \d+\)/)
            start = page.index(/\(Docket No(s)?\. \d+\)/)
            party_str = page[start..].gsub(/\(Docket No(s)?\. \d+\)/, '').strip.split(/\n\n/).reject(&:blank?)[0]
            parties = parties(party_str, court_id, case_id)
          else
            page = page.gsub(/ORDER(\s+.+)+/,'').gsub(')',') ')
            parties, lower_court_name, lower_case_id, lower_judge_name = page_parse(page, court_id, case_id)
          end
        elsif decision_type == 'Rule 23'
          page = page.gsub(/ORDER(\s+.+)+/,'').gsub(/OPINION(\s+.+)+/,'').gsub(')',') ')
          parties, lower_court_name, lower_case_id, lower_judge_name = page_parse(page, court_id, case_id)
        else
          message = "ERROR!!! File: #{file_name}".red
          logger.info message
        end
      end
    end
    info = {
      court_id: court_id,
      case_id: case_id,
      case_name: case_name,
      case_filed_date: filing_date,
      case_description: notes,
      status_as_of_date: status,
      lower_case_id: lower_case_id,
      data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/'
    }
    add_info = {
      court_id: court_id,
      case_id: case_id,
      lower_court_name: lower_court_name,
      lower_case_id: lower_case_id,
      lower_judge_name: lower_judge_name,
      data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/'
    }
    add_info = nil if add_info[:lower_court_name].blank? && add_info[:lower_case_id].blank? && add_info[:lower_judge_name].blank?
    [info, add_info, parties, link]
  end

  def page_parse(page, court_id, case_id)
    rows = rows(page)
    parties = []
    lower_court_name = nil
    lower_case_id = nil
    lower_judge_name = nil
    unless rows.blank?
      left_row, right_row = lr_rows(rows)
      parties = parties(left_row, court_id, case_id)
      lower_court_name = right_row[0].gsub('Appeal from the','').strip[0..254] unless right_row[0].blank?
      lower_case_id = right_row[1].gsub(/No(s)?\./,'').strip[0..254] unless right_row[1].blank?
      lower_judge_name = right_row[2].strip unless right_row[2].blank?
    end
    [parties, lower_court_name, lower_case_id, lower_judge_name]
  end

  def parties(row, court_id, case_id)
    row = row.gsub(/\s/,' ').squeeze(' ').gsub('vs.', ' v. ')
    row = row.gsub(/[Ii][Nn] [Rr][Ee]/,'').gsub('Appellant, and', 'Appellant, v.').gsub('Appellee, and', 'Appellee, v. ')
    row = row.gsub('—', ' ').gsub(/Appellee[,.] [^v.]/, 'Appellee v. ').gsub(/Appellant[,.] [^v.]/, 'Appellant v. ')
    row = row.gsub(' Appellee (', ' Appellee v. (').gsub(' Appellant (', ' Appellant v. (').gsub('Respondents','Respondents v. ')
    row = row.gsub('Defendants-Appellees', 'Defendants-Appellees v. ').gsub('Defendants-Appellants', 'Defendants-Appellants v. ')
    row = row.gsub(/Defendants[^-]/, 'Defendants v. ').gsub('Cross-Appellees', 'Cross-Appellees v. ').gsub('Plaintiff-Appellee', 'Plaintiff-Appellee v. ')
    row = row.gsub('Defendant-Appellant', ', Defendant-Appellant v. ').gsub('Respondent-Appellant', 'Respondent-Appellant v. ')
    row = row.gsub('Minor-Respondent-Appellee', 'Minor-Respondent-Appellee v. ')
    rows = row.split('v.').reject(&:blank?)
    parties = []
    rows.each do |item|
      party_str = item.strip.gsub(/\W+$/,'').gsub('_','').squeeze('- ').strip
      party_name = party_str.gsub(/[^.,;() ]+(( and )?[^.,;() ]+ (- )?){0,4}[^.,;() ]+$/,'').gsub(/\W+$/,'').strip
      party_type = party_str.gsub(party_name,'').gsub(/\W+$/,'').gsub(/^\W+/,'').gsub(/\s*-\s*/,'-').gsub(/s$/,'').strip
      next unless party_type.downcase.include?('appellee') || party_type.downcase.include?('appellant') ||
        party_type.downcase.include?('petitioner') || party_type.downcase.include?('respondent') ||
        party_type.downcase.include?('plaintiff') || party_type.downcase.include?('defendant')

      if party_name.include?('(') && !party_name.include?(')')
        party_name = "#{party_name})"
      end
      unless party_name.blank? || party_type.blank?
        if party_name.include? ';'
          party_names = party_name.split(/;|; and/).reject(&:blank?)
          party_names.each do |pn|
            if pn.length > 300
              if party_name.length > 300 && party_name.include?('.,')
                party_names = party_name.split(/\.,|\., and/).reject(&:blank?)
                party_names.each do |pn|
                  pn = party_name_clear(pn)
                  parties << { court_id: court_id, case_id: case_id,
                               is_lawyer: 0, party_name: pn, party_type: party_type,
                               data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/' } unless pn.blank? || pn.length > 400
                end
              elsif party_name.length > 300 && party_name.include?(',')
                party_names = party_name.split(/,|, and/).reject(&:blank?)
                party_names.each do |pn|
                  pn = party_name_clear(pn)
                  parties << { court_id: court_id, case_id: case_id,
                               is_lawyer: 0, party_name: pn, party_type: party_type,
                               data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/' } unless pn.blank? || pn.length > 400
                end
              else
                party_name = party_name_clear(party_name)
                parties << { court_id: court_id, case_id: case_id,
                             is_lawyer: 0, party_name: party_name, party_type: party_type,
                             data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/' } unless party_name.length > 400
              end
            else
              pn = party_name_clear(pn)
              parties << { court_id: court_id, case_id: case_id,
                           is_lawyer: 0, party_name: pn, party_type: party_type,
                           data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/' } unless pn.blank? || pn.length > 400
            end
          end
        elsif party_name.length > 300 && party_name.include?('.,')
          party_names = party_name.split(/\.,|\., and/).reject(&:blank?)
          party_names.each do |pn|
            pn = party_name_clear(pn)
            parties << { court_id: court_id, case_id: case_id,
                         is_lawyer: 0, party_name: pn, party_type: party_type,
                         data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/' } unless pn.blank? || pn.length > 400
          end
        elsif party_name.length > 300 && party_name.include?(',')
          party_names = party_name.split(/,|, and/).reject(&:blank?)
          party_names.each do |pn|
            pn = party_name_clear(pn)
            parties << { court_id: court_id, case_id: case_id,
                         is_lawyer: 0, party_name: pn, party_type: party_type,
                         data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/' } unless pn.blank? || pn.length > 400
          end
        else
          party_name = party_name_clear(party_name)
          parties << { court_id: court_id, case_id: case_id,
                       is_lawyer: 0, party_name: party_name, party_type: party_type,
                       data_source_url: 'https://www.illinoiscourts.gov/top-level-opinions/' } unless party_name.length > 400
        end
      end
    end
    parties
  end

  def party_name_clear(party_name)
    party_name = party_name.strip.gsub(/^\./,'').gsub(/^and /,'').gsub(/^\(/,'').squeeze(' ').strip
    party_name = party_name.gsub('(','') if party_name.include?('(') && !party_name.include?(')')
    party_name = party_name.gsub(')','') if party_name.include?(')') && !party_name.include?('(')
    party_name = nil if party_name.blank?
    party_name
  end

  def rows(page)
    start_index = page.index(/\n(.+)?    \)(    (.+)?| )/)
    page = page[start_index..]
    end_index = page.rindex(/\n(.+)?    \)(    (.+)?| )/)
    end_length = page.scan(/(\n(.+)?    \)(    (.+)?| ))/)
    end_length = end_length.blank? ? 0 : end_length[-1][0].length
    return if end_index.blank? || end_length.blank?
    page = page[..end_index + end_length]
    rows = page.split(/\n/).reject(&:blank?)
    rows
  end

  def lr_rows(rows)
    left_rows = []
    right_rows = []
    rows.each do |row|
      row = row.split(')')
      left_row = row[0]
      left_row = left_row.squeeze(' ').strip unless left_row.blank?
      right_row = row[1]
      right_row = right_row.squeeze(' ').strip unless right_row.blank?
      left_rows << left_row
      right_rows << right_row
    end
    left_rows = left_rows.reject(&:blank?)
    left_row = left_rows.join(' ')
    right_rows.map!{|item| if item == ' ' then '|' elsif item.blank? then item else item.gsub(/(Case)? No(s)?\./,' | No.') end}
    right_row = right_rows.join(' ').gsub(/(No(s)?\.)/,"| \1").squeeze(' | ').split('|').reject(&:blank?).map {|item| item.gsub('','').strip}
    [left_row, right_row]
  end
end
