require_relative 'keeper'

class Parser < Hamster::Parser
  def initialize
    super
    @pdf_parser = PdfParser.new
    @keeper = Keeper.new
  end

  def get_links_from_landing_page(html)
    regex = /20[1-2][0-9]\/index.html/i
    links_array = []
    document = Nokogiri::HTML html
    document.css("li a").map do |link|
      if link['href'][regex] && link['href'][/\d+/].to_i > 2015
        links_array << link['href']
      end
    end
    links_array
  end

  def fetch_data_from_pdf(pdf_link, decision_type, reader)
    begin
      sub_data =  reader.page(1).text
      gsub_data =  reader.page(1).text.gsub(/\s+/, ' ')
      if gsub_data.empty?
        return ''
      end
      gsub_last_page_data =  reader.pages.last.text.gsub(/\s+/, ' ')

      if decision_type.include?("MD")
        lower_court_details = @pdf_parser.fetch_lower_court_details(gsub_data, "Memorandum")
        case_filled_date = @pdf_parser.fetch_case_filed(reader)
        status_as_of_date = @pdf_parser.fetch_status_as_of_date(gsub_last_page_data, "Memorandum")
        activity_date = @pdf_parser.fetch_case_filed_date(gsub_data, 'FILED')
        petitioner = @pdf_parser.fetch_petitioner_respondent(sub_data, "Memorandum", "Petitioner")
        respondent = @pdf_parser.fetch_petitioner_respondent(sub_data, "Memorandum", "Respondent")
      elsif decision_type.include?("SO")
        lower_court_details = @pdf_parser.fetch_lower_court_details(gsub_data, "Signed Opinion")
        status_as_of_date = lower_court_details['status_as_of_date']
        case_filled_date = @pdf_parser.fetch_case_filed_date(gsub_data, 'Submitted:')
        activity_date = @pdf_parser.fetch_case_filed_date(gsub_data, 'Filed:')
        petitioner = @pdf_parser.fetch_petitioner_respondent(sub_data, "Signed Opinion", "Petitioner")
        respondent = @pdf_parser.fetch_petitioner_respondent(sub_data, "Signed Opinion", "Respondent")
      else
        lower_court_details = @pdf_parser.fetch_lower_court_details(gsub_data, 'other')
        case_filled_date = @pdf_parser.fetch_case_filed(reader)
        status_as_of_date = @pdf_parser.fetch_status_as_of_date(gsub_last_page_data, "other")
        activity_date = @pdf_parser.fetch_case_filed_date(gsub_data, 'FILED')
        petitioner = @pdf_parser.fetch_petitioner_respondent(sub_data, "other", "Petitioner")
        respondent = @pdf_parser.fetch_petitioner_respondent(sub_data, "other", "Respondent")
      end
      sub = {Petitioner: petitioner, Respondent: respondent, lower_court_name: lower_court_details['name'], lower_case_id: lower_court_details['id'], lower_court_judge_name: lower_court_details['judge_name'], case_filled_date: case_filled_date, activity_date: activity_date, status_as_of_date: status_as_of_date}
      return sub
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
    end
  end

end
