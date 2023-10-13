class Parser < Hamster::Parser

  def parse_site(page)
    elems             = []
    case_name         = []
    site              = Nokogiri::HTML(page)
    pdf_url           = site.css('td.ms-vb2 a')
    case_descriptions = site.css('div.ms-rtestate-field')[1..-1]
    pdf_info  = site.css('td.ms-vb2') #odd возвращает начальную инфу о табле even всё остальное и ссылку
    pdf_info.each_with_index { |val, idx| idx&.even? ? case_name << val : next }
    case_name.each_with_index do |name, i|
      info                    = {}
      info[:case_name]        = name.text
      info[:link]             = (('https://www.courts.ri.gov') + pdf_url[i]['href']).gsub(' ', '%20')
      info[:activity_date]    = Time.parse(name.text.split('(').last.gsub(')', ''))
      info[:file]             = pdf_url[i].text
      info[:case_description] = case_descriptions[i].nil? ? nil : case_descriptions[i].text.gsub(/\t/, ' ').strip
      (info[:case_description].nil? || info[:case_description].empty?) ? next : elems << info
    end
    elems
  end

  def parse_opinions(pdf)
    data                 = []
    data_general         = []
    data_accusation      = []
    data_defend          = []
    data_firm_accusation = []
    data_firm_defend     = []
    pdf_pages            = PDF::Reader.new(open(pdf)).pages
    last_page            = pdf_pages.last.text
    date                 = Date.parse(last_page)
    if last_page.match(/order\/opinion cover sheet/i).to_s.strip.downcase == 'order/opinion cover sheet'
      keyword = 'order'
    elsif !last_page.match(/opinion cover sheet/i).to_s.gsub(/cover sheet/i, '').strip.downcase.empty?
      keyword = last_page.match(/opinion cover sheet/i).to_s.gsub(/cover sheet/i, '').strip.downcase
    elsif !last_page.match(/order cover sheet/i).to_s.gsub(/cover sheet/i, '').strip.downcase.empty?
      keyword = last_page.match(/order cover sheet/i).to_s.gsub(/cover sheet/i, '').strip.downcase
    else
      keyword = 'order'
    end
    if !last_page.match(/date #{keyword} filed/i).nil?
      date_phrase = (last_page.match(/date #{keyword} filed.+[0-9]/i) || last_page.match(/date #{keyword} filed/i)).to_s
    else
      date_phrase = last_page.match(/date opi.+filed.+[0-9]/i).to_s
    end

    first_case_id = last_page.match(/(No.)(.+\n)/).to_s.strip
    case_prhase   = last_page.match(/(?<=#{keyword.upcase} COVER SHEET)(.+)(?=Case Number)/mi).to_s.strip
    if last_page.match(/order\/opinion cover sheet/i).to_s.downcase == 'order/opinion cover sheet'
      if last_page.match(/(?<=TITLE OF CASE)(.+)(?=CASE NO)/m).nil?
        case_name = last_page.match(/(?<=Title of Case)(.+)(?=Case Number)/m).to_s.gsub(':', '').gsub(/\s{1,}/, ' ').strip
      else
        case_name = last_page.match(/(?<=TITLE OF CASE)(.+)(?=CASE NO)/m).to_s.gsub(':', '').gsub(/\s{1,}/, ' ').strip
      end
    else
      case_name = case_prhase.gsub(first_case_id, '').gsub(/title of case/mi, '').gsub(/\s{2,}/, ' ').strip
    end
    court_id     = 340
    all_case     = []
    pdf_for_case = last_page
    loop do
      if pdf_for_case.match(/(No.+[0-9])(.+\n)/).nil?
        first_phrase  = (pdf_for_case.match(/SU.[0-9].+MP/) || pdf_for_case.match(/SU.[0-9].+M.P/) || pdf_for_case.match(/SU.[0-9].+C.A/) || pdf_for_case.match(/SU.[0-9].+appeal/i)).to_s
        pdf_for_case.gsub!(first_phrase, '')
        third_phrase  = first_phrase.gsub(/\s{1,}/m, ' ').gsub(',', '').gsub(/case number/i, '').split(' ')
        return_phrase = third_phrase.map! {|elem| elem.gsub('P', 'P, ')}.join('').strip.gsub(/,$/, '')
        return_phrase.gsub(',', '').split(' ').each {|elem| case_name.gsub!(elem, '')}
      else
        return_phrase = (pdf_for_case.match(/(No\.)(.+\w\.)/) || pdf_for_case.match(/(No\.)(.+\w\n)/)).to_s.strip.gsub(/\.$/, '')
      end
      return_phrase.empty? ? break : all_case << return_phrase

      pdf_for_case.gsub!(return_phrase, '')
    end
    cases = all_case.map {|case_num| case_num.match(/\d.+/).to_s}
    lower_case_id          = []
    parse_lower_case_first = last_page.match(/(?<=Title of Case)(.+)(Date #{keyword} filed)/im)
    parse_lower_case_two   = last_page.match(/(?<=Title of Case)(.+)(Date opi.+filed)/im)
    parse_lower_case_id    = (parse_lower_case_first || parse_lower_case_two).to_s.strip
    loop do
      return_phrase = parse_lower_case_id.match(/\(.+\)/).to_s.strip
      return_phrase.empty? ? break : lower_case_id << return_phrase.gsub('(', '').gsub(')', '')
      parse_lower_case_id.gsub!(return_phrase, '')
    end

    def accusation_law(pdf)
       finish = []
       [[['Attorney for State'], [pdf.match(/(?<=For State)(.+)(?=For Defendant)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for State'], [pdf.match(/(?<=For State)(.+)(?=For Respondent)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Plaintiff'], [pdf.match(/(?<=For Plaintiff)(.+)(?=For Defendant)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for the Plaintiff'], [pdf.match(/(?<=For the Plaintiff)(.+)(?=For the Defendant)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Petitioner'], [pdf.match(/(?<=For Petitioner)(.+)(?=For Respondent)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Petitioner'], [pdf.match(/(?<=For Petitioner)(.+)(?=For State of Rhode Island)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Claimant'], [pdf.match(/(?<=For Claimant)(.+)(?=For Defendant)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Unauthorized Practice of Law Committee'], [pdf.match(/(?<=For Unauthorized Practice of Law Committee)(.+)(?=For Respondent)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Trustees'], [pdf.match(/(?<=For Trustees)(.+)(?=For Benefeciares)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Trustees'], [pdf.match(/(?<=For Trustees)(.+)(?=For Beneficiaries)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Applicant'], [pdf.match(/(?<=For Applicant)(.+)(?=For State)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]],
       [['Attorney for Appelant'], [pdf.match(/(?<=For Appelant)(.+)(?=For Appellee)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
       ].each {|el| el[1].join('').empty? ? next : finish << el}
       finish[0]
    end

    def defend_law(pdf)
      finish                      = []
      defendant_end               = [['Attorney for Defendant'], [pdf.match(/(?<=For Defendant)(.+)(?=SU.CMS)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
      respondent_end              = [['Attorney for Respondent'], [pdf.match(/(?<=For Respondent)(.+)(?=SU.CMS)/m).to_s.gsub(':', '').gsub(/\s{1,}/, ' ').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
      plaintiff_the_end           = [['Attorney for the Defendant'], [pdf.match(/(?<=For the Defendant)(.+)(?=SU.CMS)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
      island_end                  = [['Attorney for State of Rhode Island'], [pdf.match(/(?<=For the Defendant)(.+)(?=SU.CMS)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
      benefeciares_end            = [['Attorney for Benefeciares'], [pdf.match(/(?<=For the Benefeciares)(.+)(?=SU.CMS)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
      benefeciares_end_two        = [['Attorney for Beneficiaries'], [pdf.match(/(?<=For the Beneficiaries)(.+)(?=SU.CMS)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
      state_end                   = [['Attorney for State'], [pdf.match(/(?<=For State)(.+)(?=SU.CMS)/m).to_s.gsub(':', '').gsub(/\s{1,}/, ' ').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
      appellee_end                = [['Attorney for Appellee'], [pdf.match(/(?<=For Appellee)(.+)(?=SU.CMS)/m).to_s.gsub(':', '').gsub(/Attorney.+on Appeal/i, '').gsub(/\s{1,}/, ' ').strip]]
      [defendant_end, respondent_end, plaintiff_the_end,
       island_end, benefeciares_end, benefeciares_end_two,
       state_end, appellee_end].each {|el| el[1].join('').empty? ? next : finish << el}
      finish[0]
    end
    cases.each do |case_id|
      info_accusation      = {}
      firm_accusation      = {}
      info_defend          = {}
      firm_defend          = {}
      info_general         = {}
      info_accusation[:is_lawyer]     = 1
      info_accusation[:court_id]      = court_id
      info_accusation[:case_id]       = case_id
      info_accusation[:lower_case_id] = lower_case_id.join(', ')
      info_accusation[:party_name]    = !accusation_law(last_page).nil? ? accusation_law(last_page)[1].join('').gsub(/^. /, '') : nil
      info_accusation[:party_type]    = !accusation_law(last_page).nil? ? accusation_law(last_page)[0].join('').gsub(/^. /, '') : nil
      data_accusation << info_accusation

      info_defend[:is_lawyer]     = 1
      info_defend[:court_id]      = court_id
      info_defend[:case_id]       = case_id
      info_defend[:lower_case_id] = lower_case_id.join(', ') #dont will write
      info_defend[:party_name]    = !defend_law(last_page).nil? ? defend_law(last_page)[1].join('').gsub(/^. /, '').strip : nil
      info_defend[:party_type]    = !defend_law(last_page).nil? ? defend_law(last_page)[0].join('').gsub(/^. /, '').strip : nil
      data_defend << info_defend

      firm_accusation[:is_lawyer]  = 0
      firm_accusation[:case_id]    = case_id
      firm_accusation[:court_id]   = court_id
      firm_accusation[:party_name] = !case_name.split('v.')[0].nil? ? case_name.split('v.')[0].strip : nil
      firm_accusation[:party_type] = !accusation_law(last_page).nil? ? accusation_law(last_page)[0][0].gsub('Attorney for ', '').gsub('the ', '').strip : nil
      data_firm_accusation << firm_accusation

      firm_defend[:is_lawyer]  = 0
      firm_defend[:case_id]    = case_id
      firm_defend[:court_id]   = court_id
      firm_defend[:party_name] = !case_name.split('v.')[1].nil? ? case_name.split('v.')[1].strip : nil
      firm_defend[:party_type] = !defend_law(last_page).nil? ? defend_law(last_page)[0][0].gsub('Attorney for ', '').gsub('the ', '').strip : nil
      data_firm_defend << firm_defend

      lower_case_id.each {|case_id| case_name.gsub!(case_id, '')}
      all_case.each {|id_case| case_name.gsub!(id_case, '')}
      info_general[:court_id]      = court_id
      info_general[:case_id]       = case_id
      info_general[:case_name]     = case_name.gsub('(', '').gsub(')', '').strip
      info_general[:lower_case_id] = lower_case_id.join(', ')
      info_general[:activity_date] = date
        if !last_page.match(/#{date_phrase}.+written by/im).nil?
          info_general[:judge_name] = last_page.match(/#{date_phrase}.+written by/im).to_s.gsub(date_phrase, '').gsub(/justices/i, '').gsub(/written by/i, '').gsub(':', '').gsub(/\s{1,}/, ' ').strip
        else
          info_general[:judge_name] = last_page.match(/#{date_phrase}.+source of appeal/im).to_s.gsub(date_phrase, '').gsub(/justices/i, '').gsub(/source of appeal/i, '').gsub(/\s{1,}/, ' ').strip
        end
      info_general[:lower_court_name]  = last_page.match(/(?<=Source of Appeal)(.+?)(?=judicial officer)/mi).nil? ? (last_page.match(/(?<=\n)(.+\n)(?=Source of Appeal)/i) || last_page.match(/(?<=source of appeal)(.+)(?=\n)/i)).to_s.delete(':').strip : last_page.match(/(?<=Source of Appeal)(.+?)(?=judicial officer)/mi).to_s.gsub(/\s{2,}/, ' ').strip
      info_general[:status_as_of_date] = "has #{keyword}" #'has opinion' or 'has order'
      info_general[:activity_type]     = keyword.capitalize
      data_general << info_general
    end ###
    data       = []
    party_data = [data_accusation, data_defend, data_firm_accusation, data_firm_defend].flatten
    party_data.each {|party| !party[:party_name].nil? ? data << party : next}
    [data_general, data]
  rescue => e
    Hamster.logger.error(e.full_message)
    nil
  end
end
