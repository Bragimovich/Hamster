require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def page_parse(page)
    body = Nokogiri::HTML.parse(page)
    case_info = case_info(body)
    parties = parties(body, case_info[:case_id], case_info[:court_id])
    activities = activities(body, case_info[:case_id], case_info[:court_id])
    [case_info, parties, activities]
  end

  def case_info(body)
    courts =
      [{name: 'County Court at Law No. 1', id: 105},
       {name: 'County Court at Law No. 2', id: 106},
       {name: 'County Court at Law No. 3', id: 107},
       {name: 'County Court at Law No. 4', id: 108},
       {name: 'County Court at Law No. 5', id: 109},
       {name: 'Probate Court', id: 110},
       {name: 'Probate', id: 110},
       {name: 'Probate Court No. 2', id: 111},
       {name: 'Probate Court No. 3', id: 112},
       {name: 'Civil', id: 120},
       {name: '14th District Court', id: 120},
       {name: 'District Courts', id: 121},
       {name: '44th District Court', id: 121},
       {name: '68th District Court', id: 122},
       {name: '95th District Court', id: 123},
       {name: '101st District Court', id: 124},
       {name: '116th District Court', id: 125},
       {name: '134th District Court', id: 126},
       {name: '160th District Court', id: 127},
       {name: '162nd District Court', id: 128},
       {name: '191st District Court', id: 129},
       {name: '192nd District Court', id: 130},
       {name: '193rd District Court', id: 131},
       {name: '254th District Court', id: 113},
       {name: '255th District Court', id: 114},
       {name: 'Family', id: 114},
       {name: '256th District Court', id: 115},
       {name: '298th District Court', id: 132},
       {name: '301st District Court', id: 116},
       {name: '302nd District Court', id: 117},
       {name: '303rd District Court', id: 118},
       {name: '330th District Court', id: 119}
      ]
    case_info_body = body.css('#caseInformationDiv #divCaseInformation_body')
    case_info_body.css('#divCaseInformation_header').remove
    case_info_body = case_info_body.css('div p')
    case_name = nil
    case_id = nil
    case_court = nil
    case_judicial_officer = nil
    case_filed_date = nil
    case_type = nil
    case_status = nil
    case_info_body.each do |item|
      if item.to_s.include? ' | '
        case_name = item.text[item.text.index('|')+1..].strip
      end
      if item.to_s.include? '<span class="text-muted">Case Number</span>'
        item.css('.text-muted').remove
        case_id = item.text.strip
      end
      if item.to_s.include? '<span class="text-muted">Court</span>'
        item.css('.text-muted').remove
        case_court = item.text.strip
      end
      if item.to_s.include? '<span class="text-muted">Judicial Officer</span>'
        item.css('.text-muted').remove
        case_judicial_officer = item.text.strip
      end
      if item.to_s.include? '<span class="text-muted">File Date</span>'
        item.css('.text-muted').remove
        case_filed_date = item.text.strip
        case_filed_date = Date.strptime(case_filed_date,'%m/%d/%Y')
      end
      if item.to_s.include? '<span class="text-muted">Case Type</span>'
        item.css('.text-muted').remove
        case_type = item.text.strip
      end
      if item.to_s.include? '<span class="text-muted">Case Status</span>'
        item.css('.text-muted').remove
        case_status = item.text.strip
      end
    end
    court_id = courts.detect{|court| court[:name] == case_court}
    court_id = court_id[:id] unless court_id.blank?
    court_id = 122 if court_id.blank?
    disposition_raw = body.css('#dispositionInformationDiv')
    disposition_raw.css('.divDispositionInformation_header').remove
    disposition_raw = disposition_raw.css('p').map{|item| if item.text.include?('Judgment Type') then item else nil end}.reject(&:blank?)
    disposition = nil
    unless disposition_raw.blank?
      disposition_raw = disposition_raw[-1] unless disposition_raw.blank?
      disposition = disposition_raw.to_s.split('<br>')[-1]
      disposition = Nokogiri::HTML.parse(disposition).text.strip
    end
    case_info = {
      case_name: case_name,
      case_id: case_id,
      court_id: court_id,
      case_judicial_officer: case_judicial_officer,
      case_filed_date: case_filed_date,
      case_type: case_type,
      case_status: case_status,
      disposition: disposition
    }
    case_info
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def parties(body, case_id, court_id)
    parties = []
    parties_info = body.css('#partyInformationDiv #divPartyInformation_body')
    parties_info.css('#divPartyInformation_header').remove
    parties_info = parties_info.to_s.split('<hr>')
    parties_info.each do |party|
      party = Nokogiri::HTML.parse(party)
      party_type = ''
      party_left = party.css('.col-md-8')
      party_left.each do |item|
        info = item.css('p')[0]
        address = nil
        if item.css('p').to_a.count > 1 && item.to_s.include?('>Address<')
          item_address = item.to_s.split('>Address')[-1]
          address = Nokogiri::HTML.parse(item_address).css('p')
        end
        party_type = info.css('span').text.squeeze(' ').strip
        info.css('span').remove
        party_name = info.text.strip
        address = address.to_s.split('<br>').map!{|item| Nokogiri::HTML.parse(item).text.strip}
        if address.blank?
          law_firm = nil
          firm_address = nil
          city = nil
          state = nil
          zip = nil
        else
          isc = address[-1].split
          address.pop
          zip = isc[-1]
          isc.pop
          state = isc[-1]
          isc.pop
          city = isc.join(' ')
          address = address.join(', ')
          address = address.gsub(' ','').squeeze(' ')
          address = address.gsub(/\s+,/,',').gsub('istrict,','istrict')
          address = address.gsub(/[Bb][Oo]?[Uu]?[Ll][Ee]?[Vv]?[Aa]?[Rr]?[Dd]?\.?,/){|item| item.chop!}
          address = address.gsub(/[Ss][Tt][Rr]?[Ee]?[Ee]?[Tt]?\.?,/){|item| item.chop!}
          address = address.gsub(/[Aa][Vv][Ee][Nn]?[Uu]?[Ee]?\.?,/){|item| item.chop!}
          address = address.gsub(/([Dd][Rr]\.?|[Dd][Rr][Ii][Vv][Ee]),/){|item| item.chop!}
          address = address.gsub(/([Rr][Dd]\.?|[Rr][Oo][Aa][Dd]),/){|item| item.chop!}
          address = address.gsub(/([Bb][Ll][Dd][Gg]?\.?|[Bb][Uu][Ii][Ll][Dd][Ii][Nn][Gg]),/){|item| item.chop!}
          address = address.gsub(/([Hh][Ww][Yy]\.?|[Hh][Ii][Gg][Hh][Ww][Aa][Yy]),/){|item| item.chop!}
          address = address.gsub(/([Ff][Ll]\.?|[Ff][Ll][Oo][Oo][Rr]?),/){|item| item.chop!}
          address = address.gsub(/([Pp][Kk][Ww][Yy]\.?|[Pp][Aa][Rr][Kk][Ww][Aa][Yy]),/){|item| item.chop!}
          address = address.gsub(/([Tt][Oo][Ww][Ee][Rr][Ss]?),/){|item| item.chop!}
          address = address.gsub(/([Ss][Tt][Aa][Rr][Ss]?),/){|item| item.chop!}
          address = address.gsub(/([Cc][Ee][Nn][Tt][Ee][Rr]),/){|item| item.chop!}
          address = address.gsub(/([Pp][Ll][Zz]|[Pp][Ll][Aa][Zz][Aa]),/){|item| item.chop!}
          address = address.gsub(/([Cc]ir\.?(cle)?),/){|item| item.chop!}
          address = address.gsub(/([Pp][Ll]\.?([Aa][Cc][Ee])?),/){|item| item.chop!}
          address = address.gsub(/([Rr][Oo][Uu][Tt][Ee]),/){|item| item.chop!}
          address = address.gsub(/([Ll][Aa]?[Nn][Ee]?),/){|item| item.chop!}
          address = address.gsub(/([Ss][Uu][Ii][Tt][Ee]?),/){|item| item.chop!}
          address = address.gsub(/([Nn][Oo][Rr][Tt][Hh]|[Ww][Ee][Ss][Tt]|[Ss][Oo][Uu][Tt][Hh]|[Ee][Aa][Ss][Tt]),/){|item| item.chop!}
          address = address.gsub(/( [Cc]\.?[Tt]\.?| [Jj]\.?[Rr]\.?| [NnSs]\.?[Ww]\.?| [Rr]\.?[NnLl]\.?| [NnSs]\.?[Ee]\.?),/){|item| item.chop!}
          address = address.gsub(/( [Ww][Aa][Yy]| [Bb][Rr][Oo][Aa][Dd][Ww][Aa][Yy]| [Rr][Ee][Aa][Ll]| [Aa][Nn][Dd]| [Ss][Qq][Uu][Aa][Rr][Ee]| [Ss][Ll][Oo][Uu][Gg][Hh]| [Ww][Ii][Nn][Gg]| [Mm][Aa][Rr][Kk][Ee][Tt]),/){|item| item.chop!}
          address = address.gsub(/( [Uu]nit| [Cc][Oo][Uu][Rr][Tt]| [Pp][Aa][Rr][Kk]| [Ee][Nn][Tt][Ee][Rr][Pp][Rr][Ii][Ss][Ee]| [Pp][Aa][Cc][Ii][Ff][Ii][Cc][Aa]| [Cc][Aa][Rr][Ll][Ss][Bb][Aa][Dd]| [Cc][Aa][Nn][Yy][Oo][Nn]),/){|item| item.chop!}
          address = address.gsub(/( [Aa][Mm][Ee][Rr][Ii][Cc][Aa][Ss]| [Ss][Aa][Nn][Dd][Ee][Rr][Ss]| [Gg][Rr][Aa][Nn][Dd]| [Ii][Ss][Ll][Aa][Nn][Dd]| [Vv][Ee][Nn][Tt][Uu][Rr][Aa]| [Ll][Oo][Oo][Pp]| [Pp][Yy][Rr][Aa][Mm][Ii][Dd]),/){|item| item.chop!}
          address = address.gsub(/( [Tt]ordo| [Hh]all| [Hh]ouse| [Ss]onoma| [Cc]rossing| [Uu]pstairs| [Pp]residio| [Mm]all),/){|item| item.chop!}
          address = address.gsub(/( [Aa]ngeloalcid| [Ee]xpy| [Cc]ourthouse| [Cc][Tt][Rr]| [Pp][Mm][Bb]),/){|item| item.chop!}
          address = address.gsub(/( [Dd][Rr] [Ee]| [Ll][Nn] #[Cc]| [Pp]ark [Ee]ast| #| [Hh]all of [Aa]dmin| [Cc]ity [Aa]ttorney),/){|item| item.chop!}
          address = address.gsub(/( [Mm]itchell [Nn]| [Cc]hief [Cc]ounsel),/){|item| item.chop!}.gsub(/( [Tt][Rr][Aa][Ii][Ll]),/){|item| item.chop!}
          address = address.gsub(/( [Ff][Rr][Ww][Yy]),/){|item| item.chop!}
          address = address.gsub(/(([Ss][Uu][Ii][Tt][Ee]?|[Aa]ve|[Aa]venue|[Bb]ox|[Uu]nit|[Pp]ark|[Bb][Ll][Vv][Dd]) [a-zA-Z]),/){|item| item.chop!}
          address = address.gsub(/, (P\.?O\.? [Bb][Oo][Xx] [^,]+),/){|item| item.chop!}.gsub(/, ((Building|Bldg) [^,]+),/){|item| item.chop!}
          address = address.gsub(/, (\d+ [^,]+),/){|item| item.chop!}.gsub(/(-\d+[a-zA-Z]+),/){|item| item.chop!}
          address = address.gsub(/(\d+ [^,]*([Dd][Rr][Ii][Vv][Ee]|[Ss][Qq]|[Aa][Vv][Ee]([Nn][Uu][Ee])?|[Hh][Ww][Yy]|[Ww][Aa][Yy]|[Ss][Tt]([Ee])?|[Ll][Nn]|[Ff][Ww][Yy]|[Pp][Kk]|[Ss][Tt]([Rr][Ee][Ee][Tt])?|[Rr][Oo][Uu][Tt][Ee]|[Pp][Ll][Cc]|[Bb][Ll][Dd][Gg])+ [^,]*),/){|item| item.chop!}
          address = address.gsub(/(\d+ [^,]*([Dd][Rr][Ii][Vv][Ee]|[Ss][Qq]|[Aa][Vv][Ee]([Nn][Uu][Ee])?|[Hh][Ww][Yy]|[Ww][Aa][Yy]|[Ss][Tt]([Ee])?|[Ll][Nn]|[Ff][Ww][Yy]|[Pp][Kk]|[Ss][Tt]([Rr][Ee][Ee][Tt])?|[Rr][Oo][Uu][Tt][Ee]|[Pp][Ll][Cc]|[Bb][Ll][Dd][Gg])+),/){|item| item.chop!}
          address = address.gsub(/(\d),/){|item| item.chop!}
          address = address.squeeze(' ').split(',')
          if address.count == 1
            firm_address = address[0].strip
            law_firm = nil
          else
            firm_address = address[-1].strip
            address.pop(1)
            address = address.join(',')
            law_firm = address.strip
          end
        end
        party_name = nil if party_name.blank?
        party_type = nil if party_type.blank?
        law_firm = nil if law_firm.blank?
        firm_address = nil if firm_address.blank?
        city = nil if city.blank?
        state = nil if state.blank?
        zip = nil if zip.blank?
        parties << {
          case_id: case_id,
          court_id: court_id,
          is_lawyer: 0,
          party_name: party_name,
          party_type: party_type,
          party_law_firm: law_firm,
          party_address: firm_address,
          party_city: city,
          party_state: state,
          party_zip: zip,
          party_description: nil
        }
      end
      party_right = party.css('.col-md-4 .tyler-toggle-container > div > div')
      party_right.each do |party|
        party_type = "#{party_type} #{party.css('span').text}"
        party.css('span').remove
        party_name = party.text.strip
        party_name = nil if party_name.blank?
        party_type = nil if party_type.blank?
        parties << {
          case_id: case_id,
          court_id: court_id,
          is_lawyer: 1,
          party_name: party_name,
          party_type: party_type,
          party_law_firm: nil,
          party_address: nil,
          party_city: nil,
          party_state: nil,
          party_zip: nil,
          party_description: nil
        }
      end
    end
    parties.uniq!
    parties
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def activities(body, case_id, court_id)
    links_params = body.css('head').to_s
    links_params = links_params[links_params.index('var newParams')..]
    links_params = links_params[..links_params.index('};')]
    links_params = links_params.gsub('var newParams', '').gsub('= {', '').gsub('}', '').split(',').map{|item| item.strip}
    links_params = {
      caseNum: links_params[0].gsub('caseNum: "','').gsub('"',''),
      locationId: links_params[1].gsub('locationId: "','').gsub('"',''),
      caseId: links_params[2].gsub('caseId: "','').gsub('"','')
    }
    activities = []
    case_activities = body.css('#eventsInformationDiv .portal-case-event')
    case_activities.each do |item|
      type_raw = item.css('p')[0].text.strip.split('   ')
      type = type_raw[1].strip
      date = type_raw[0].strip
      date = Date.strptime(date,'%m/%d/%Y')
      links = item.css('p a').map{|item| "https://courtsportal.dallascounty.org#{item['href']}&caseNum=#{links_params[:caseNum]}&locationId=#{links_params[:locationId]}&caseId=#{links_params[:caseId]}&docType=#{item['data-doc-doctype'].gsub(' ','+')}&docName=#{item['data-doc-docname'].gsub(' ','+')}"}
      links = links.map{|item| Scraper.new.relocation(item)}
      links = links.reject(&:blank?)
      comment = item.css('p').map{|item| if item.to_s.include?('>Comment<') then item else nil end}.reject(&:blank?)
      if comment.blank?
        comment = nil
      else
        comment = Nokogiri::HTML.parse(comment[-1].to_s.split('<br>')[-1]).text.strip
      end
      activities << {
        case_id: case_id,
        court_id: court_id,
        date: date,
        type: type,
        links: links,
        comment: comment
      }
    end
    activities
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def cases(browser)
    cases = Nokogiri::HTML.parse(browser.body).css('.kgrid-card-table tbody .k-master-row')
    cases_arr = []
    cases.each do |cas|
      cases_arr << {link: "#{cas.css('.caseLink')[0]['data-url']}", case_id: "#{cas.css('.caseLink').text}"}
    end
    cases_arr
  end

  def sitekey(browser)
    Nokogiri::HTML.parse(browser.body).css('.g-recaptcha')[0]['data-sitekey'].to_s
  end

  def pages(browser)
    Nokogiri::HTML.parse(browser.body).css("#CasesGrid > div > ul > li").to_a
  end
end