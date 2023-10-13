class Parser < Hamster::Parser

  def initialize
    super
    @scraper = Scraper.new
    @pdf_parser = PdfParser.new
    @keeper = Keeper.new
  end

  def get_data_from_sub_page(html)
    document = Nokogiri::HTML html
  end

  def fetch_data_from_pdf(reader, type, pdf_link)
    
    begin
      first_page = reader.page(1).text
      if first_page.empty?
        return ''
      end
      last_page = reader.pages.last.text
      case_filed_date = @pdf_parser.fetch_case_filed_date(first_page)
      judge_name = @pdf_parser.fetch_judge_name(first_page)
      status_as_of_date = @pdf_parser.fetch_status_as_of_date(last_page)
      lower_court_name = @pdf_parser.fetch_lower_court_name(first_page)

      if type == "Plaintiff-Appellant"
        target_sentence = first_page.match(/(.*Plaintiff(?:s)?-Appellant(?:s)?.*)|(.*Cross-Appellee(?:s)?.*)|(.*Plaintiffs-Appellees.*)|(.*Petitioner-Appellee.*)|(.*Petitioner-Appellant.*)|(.*Plaintiff-Appellee.*)|(.*for Appellant(?:s)?.*)|(.*Plaintiff.*)/).to_s
        party_name,party_type,party_city,party_description,party_law_firm = store_attorney(target_sentence, reader, pdf_link)
      else
        target_sentence = first_page.match(/(.*Defendant(?:s)?-Appellee(?:s)?.*)|(.*Cross-Appellant(?:s)?.*)|(.*Defendant-Appellant.*)|(.*Respondent-Appellant.*)|(.*Respondent-Appellee.*)|(.*for Appellee(?:s)?.*)|(.*Defendant.*)/).to_s
        party_name,party_type,party_city,party_description,party_law_firm = store_attorney(target_sentence, reader, pdf_link)
      end
      {
        lower_court_name: lower_court_name,
      judge_name: judge_name,
      case_filed_date: case_filed_date,
      status_as_of_date: status_as_of_date,
      party_name: party_name,
      party_type: party_type,
      party_description: party_description,
      party_law_firm: party_law_firm,
      party_city: party_city,
      party_state: party_description
      }
    rescue  Exception => e
      logger.error(e.full_message)
      Hamster.report(to: 'Zaid Akram',message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}",use: :slack)
    end
  end

  def fetch_case_info_hash(row)
    info_hash = {}
    if row.css("td[4]")&.text.empty? == false
      info_hash['activity_date'] = row.css("td[4]")&.text
      info_hash['case_id'] = row.css("td[3]")&.text
      info_hash['case_name'] = row.css("td[2]")&.text
      info_hash['link'] = row.css("td[2]").at('a')['href']
      info_hash['activity_type'] = 'desc'
      info_hash
    else 
      if row.css("td[3]")&.text.empty? == false
        info_hash['activity_date'] = row.css("td[3]")&.text
        info_hash['case_id'] = row.css("td[2]")&.text
        info_hash['case_name'] = row.css("td[1]")&.text
        info_hash['link'] = row.css("td[1]").at('a')['href']
        info_hash['activity_type'] = 'desc'
        info_hash
      end
    end
  end

  private

  def store_attorney(target_sentence, reader, pdf_link)
    begin
      text = reader.pages.map(&:text).join("\n")
      lines = text.split("\n")
      target_index = lines.index(target_sentence)
      party_description = ""
      i = 0
      count = 0
      until lines[target_index - i] == ""
        i = i + 1
        count = count + 1
      end
      while count >= 0
        party_description << lines[target_index - count]
        count = count - 1
      end
      description = party_description.split(/\b(of|for)\b/)
      if description.length == 5
        party_name = description[0]
        party_type = "Attorney for #{description[4].split.first}"
        party_law_firm = description[2].sub(" ","")
        party_city = description[2].split.last.sub(/[" ",]/,"")
      elsif description.length == 7
        party_name = description[0]+description[1]+description[2]
        party_type = "Attorney for #{description[6].split.first}"
        party_law_firm = description[4].sub(" ","")
        party_city = description[4].split.last.sub(/[" ",]/,"")
        # puts "The case has no party_description"
      else
        begin
          if description.length == 1
            description.to_s
          else
            party_type = "Attorney for #{description[2].split.first}"
            split_description = description[0].split(",")
            if split_description.length == 6
              party_name = split_description[0]+split_description[1]+split_description[2]+split_description[3]
              party_city = split_description[4].sub(/[" ",]/,"")
            elsif split_description.length == 7
              party_name = split_description[0]+split_description[1]+split_description[2]+split_description[3]+split_description[4]
              party_city = split_description[5].sub(/[" ",]/,"")
            elsif split_description.length == 5
              party_name = split_description[0]+split_description[1]+split_description[2]
              party_city = split_description[3].sub(/[" ",]/,"")
            elsif split_description.length == 3
              party_name = split_description[0]
              party_city = split_description[1].sub(/[" ",]/,"")
            else
              party_name = split_description[0]+split_description[1]
              party_city = split_description[2].sub(/[" ",]/,"")
            end
          end
        rescue
          party_description = ""
          count = 2
          while count >= 0
            party_description << lines[target_index - count]
            count = count - 2
          end
          description = party_description.split(/\b(of|for)\b/)
          party_type = "Attorney for #{description[4].split.first}"
          party_name = description[0]
          party_law_firm = description[2].sub(" ","")
          party_city = description[2].split.last.sub(/[" ",]/,"")
        end
      end
    rescue
      logger.error("Case has no party details")
    end
    return party_name,party_type,party_city,party_description,party_law_firm
  end
end
