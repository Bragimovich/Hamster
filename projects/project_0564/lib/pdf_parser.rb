class PdfParser
  def initialize
    super
  end

  def  fetch_lower_court_name(page, type)
    if type == 'Memorandum'
      regex = %r{[a-zA-Z]+ [a-zA-Z]+}
      name = page[regex] || ''
    elsif type == 'Signed Opinion'
      data = page.gsub('_', '')
      court_name = data.split("\n")[0].split("The Honorable")[0].strip
      return '' if court_name.nil?

      name = court_name.split.last(10).join(" ") || ''
    end
    name || ''
  end

  def fetch_lower_court_id(page)
    regex = %r{([A-Za-z0-9]+(-[A-Za-z0-9]+)+)}
    court_id = page[regex]
    court_id || ''
  end

  def fetch_lower_court_judge_name(page)
    if page.include?("The Honorable")
      if page.include?("Judge")
        name_start = page.index("The Honorable") + "The Honorable".length + 1
        name_end = page[name_start..-1].index("Judge") - 1
        name = page[name_start..name_start+name_end].strip
        judge_name = name.split.last(10).join(" ")
      else
        if page.include?("The Honorable")
          line = page.split("The Honorable")[1]
          if line.include?("Case No.")
            puts"Case No."
            data = line.split("Case No")[0]
            judge_name = data.split.last(10).join(" ")
          else
            if line.include?('_')
              data = line.gsub('_', '')
              judge_name = data.split.last(10).join(" ")
            end
          end
        end
      end
    elsif  page.include?("Respondent")
        line = page.split("Respondent")[1]
        if line.include?("Filed")
          data =  page.split("Filed")[1]
          if data.include?('_')
            name = data.gsub('_', '')
            judge_name = name.split.last(10).join(" ")
          end
        else
          if line.include?('_')
            name = line.gsub('_', '')
            judge_name = name.split.last(10).join(" ")
          end
        end
    end
    judge_name || ''
  end

  def fetch_supreme_court_judge_name(page)
    if page.include?("concurring")
      judge_info = page.split("concurring")[0]
       filter_judge_info(judge_info)
    elsif page.include?("_")
      line = page.gsub('_', '')
      if line.include?("dissenting")
        judge_info = line.split("dissenting")[0]
        filter_judge_info(judge_info)
      end
      filter_judge_info(line)
    else
      return ''
    end
  end

  def filter_judge_info(judge_info)
    if judge_info.include?("p.m.")
      judge_name = judge_info.split("p.m.")[1]
      if judge_name.include?("APPEALS")
        judges_name = judge_name.split("APPEALS")[1]
        name = judges_name.split.last(100).join(" ")
      else
        name = judge_name.split.last(10).join(" ")
      end
    elsif judge_info.include?("APPEALS")
      judge_name = judge_info.split("APPEALS")[1]
      if judge_name.include?('_')
        data = judge_name.gsub('_', '')
        name = data.split.last(80).join(" ")
      else
        name = judge_name.split.last(80).join(" ")
      end
    else
      name = judge_info.split.last(10).join(" ")
    end
    name
  end

  def fetch_status_as_of_date(page, pdf_type)
    if pdf_type == 'Signed Opinion'
      array = page.split("\n")[0]
      return '' if array.nil?

      regex = %r{([A-Za-z0-9]+(-[A-Za-z0-9]+)+)}
      status = page[regex]
      case_status = array.split(status)[1]
      return '' if case_status.nil?

      status_string = case_status.split("_")[0]
      return '' if status_string.nil?

      current_status = status_string.split.last(10).join(" ")
    elsif pdf_type == 'Memorandum'
      array = page.split("\n")[0]
      return '' if array.nil?

      text = array.split("ISSUED")[0]
      return '' if text.nil?

      last_full_stop = text.rindex(".")
      status_string = text[0...last_full_stop].split(" ").last
      return '' if status_string.nil?

      current_status = status_string.split.last(10).join(" ")
    else
      return ''
    end
    current_status
  end

  def fetch_lower_court_details(page, activity_type)
    if activity_type == 'Memorandum'
      regex = %r{\([a-zA-Z]+\s[a-zA-Z]+\s([A-Za-z0-9]+(-[A-Za-z0-9]+)+)\)}
      data = page[regex] || ''
      {"name"=> fetch_lower_court_name(data, 'Memorandum'), "id"=> fetch_lower_court_id(data)}
    elsif activity_type == 'Signed Opinion'
        array = page.split('Petitioner')
        return '' if array[1].nil?
        if array.include?("Appeal from the")
          line =  array[1]&.split('Appeal from the')[1].strip
           return '' if line.nil?
        else
          if page.include?("delivered the")
            line = page.split('delivered the')[0]
          end
        end
        {"name"=> fetch_lower_court_name(line, 'Signed Opinion' ), "id"=> fetch_lower_court_id(line), "judge_name"=> fetch_lower_court_judge_name(line), "status_as_of_date"=> fetch_status_as_of_date(line, 'Signed Opinion')}
    else  activity_type == 'other'
      array = page.split('FILED')[1]
      return '' if array.nil?

      {"name"=> fetch_lower_court_name(array, 'other' ), "id"=> fetch_lower_court_id(array), "judge_name"=> fetch_supreme_court_judge_name(array), "status_as_of_date"=> fetch_status_as_of_date(array, 'other')}
    end
  end

  def fetch_case_filed(reader)
    text = reader.pages.map { |page| page.text }.join("\n")
    lines = text.split("\n")
    dates = []
    lines.each do |line|
      if line =~ /(\w+)\s+(\d{1,2}),\s+(\d{4})/
        month = $1
        day = $2.to_i
        year = $3.to_i
        begin
          dates << Date.new(year, Date::MONTHNAMES.index(month), day)
        rescue TypeError => e
          dates << 'nil'
          puts "caught exception #{e}!"
        end
      end
    end
    if dates.include?('nil')
      smallest_date = ''
    else
      smallest_date = dates.min
    end
    smallest_date || ''
  end

  def fetch_case_filed_date(gsub_data, dates)
    if gsub_data.include?(dates)
      begin
        date_string = gsub_data.match(/#{dates} (.*)/)[1]
        date = Date.parse(date_string)
      rescue Date::Error => e
        puts "caught exception #{e}!"
      end
    end
    date || ''
  end

  def memorandum_petitioner(party_descriptions)
    if party_descriptions.include?("COURT OF APPEALS")
      party = party_descriptions.match(/ COURT OF APPEALS\s+(.*)/)[1]
      if party.include?("OF APPEALS")
        party_name = party.split("APPEALS")[1]
        if party_name.include?("OF WEST VIRGINIA")
          petitioner_data = party_name.split("OF WEST VIRGINIA")[1]
        else
          petitioner_data = party_name
        end
      else
        petitioner_data = party
      end
    else
      petitioner_data = party_descriptions
    end
    party_name_last = petitioner_data.gsub(/\s+/, ' ')
    party_name_last.split("Petitioner")[0]
  end

  def memorandum_respondent(party_description)
    regex = %r{[A-Za-z]+\.\s[0-9]+-\d\d\d\d}
    data = party_description[regex]
      party_name_last = party_description.split(data)[1]
      regex2 = %r{\)}
      status = party_name_last[regex2]
      if status.nil?
        respondent_data = party_name_last
      else
        respondent_data = party_name_last.split(status)[1]
      end
    respondent = respondent_data.gsub(/\s+/, ' ')
    respondent.split("Respondent")[0]
  end

  def signed_petitioner(party_description)
    regex = %r{[A-Za-z]+\.\s[0-9]+-\d\d\d\d}
    data = party_description[regex]
    party_name_last = party_description.split(data)[1]
    if party_name_last.include?(' OF WEST VIRGINIA')
      last = party_name_last.sub('OF WEST VIRGINIA', '')
      if last.include?("APPEALS")
        petitioner_data = last.split('APPEALS')[1]
      else
        petitioner_data = last
      end
    elsif party_description.include?('v.') ||  party_description.include?('V.')
      petitioner_data = party_description.sub(/\A.*[vV]\./, "")
    else
      petitioner_data = party_name_last
    end
    if petitioner_data.include?('_')
      petitioner = petitioner_data.gsub('_', '')
    else
      petitioner = petitioner_data
    end
    party_name = petitioner.gsub(/\s+/, ' ')
    party_name.split("Petitioner")[0]
  end

  def signed_respondent(party_description)
    if party_description.include?('v.') ||  party_description.include?('V.')
      party_name_last = party_description.sub(/\A.*[vV]\./, "")
    elsif party_description.include?(' OF WEST VIRGINIA')
      last = party_description.sub!('OF WEST VIRGINIA', '')
      if last.include?("APPEALS")
        party_name_last = last.split("APPEALS")[1]
      else
        party_name_last = last
      end
    end
    if party_name_last.include?('_')
      respondent_data = party_name_last.gsub('_', '')
    else
      respondent_data = party_name_last
    end
    respondent = respondent_data.gsub(/\s+/, ' ')
    respondent.split("Respondent")[0]
  end

  def fetch_petitioner_respondent (page, pdf_type, type)
      lines = page.split("\n")

      if type == 'Petitioner'
        target_sentence = page.match(/(.*Petitioner(?:s)?.*)/).to_s
      else
        target_sentence = page.match(/(.*Respondent(?:s)?.*)/).to_s
      end

      target_index = lines.index(target_sentence)
      party_description = ""
      i = 0
      count = 10

      until lines[target_index - i] == ""
        i = i + 1
        count = count + 1
      end

      while count >= 0
        party_description << lines[target_index - count]
        count = count - 1
      end

      if pdf_type == 'Memorandum'
        if type == 'Petitioner'
         memorandum_petitioner(party_description)
        else
         memorandum_respondent(party_description)
        end
      elsif pdf_type == 'Signed Opinion'
        if type == 'Petitioner'
          signed_petitioner(party_description)
        else
          signed_respondent(party_description)
        end
      else
        { petitioner: '', respondent: ''}
      end

  end

end
