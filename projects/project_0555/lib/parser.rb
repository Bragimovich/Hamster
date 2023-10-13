# frozen_string_literal: true

class Parser < Hamster::Harvester

  BASE_URL = "https://www.iowacourts.gov"

  # attr_reader :higher_court, :lower_court

  def initialize(courts)
    super
    @lower_court  = courts[:lower_court]
    @higher_court = courts[:higher_court]
  end

  def get_each_page_cases(file_content)
    doc = Nokogiri::HTML.parse(file_content)
    h3_css_selecter = 'div.page-wrapper-full > div.inside-page-section ' +
                      '> div.container.inside-pg-content-container > div ' +
                      '> main > div > div > h3'
    doc.css(h3_css_selecter)
  end

  def get_case_info(file_content)
    doc = Nokogiri::HTML.parse(file_content)

    case_id               = doc.css('h1.page-title').text.match /(\w+)(.* )(?<case_id>\d+-\d+)/
    case_name             = doc.css('div.case-details-section-wrapper > h2')[0].text.squish
    case_filed_date       = doc.css('div.case-detail-info-item-wrap > div.inline-text-block')
                              .last.text.squish
    case_type             = nil
    case_description      = doc.css('div.case-details-section-wrapper > p')[0].text.squish
    disposition_or_status = nil
    opinion_link          = BASE_URL + 
                            doc.css(
                                  'div.inside-page-section > div.container.inside-pg-content-container ' \
                                  '> div > main > div > div > div.case-details-main-content-wrapper.main-content-wrapper ' \
                                  '> div:nth-child(2) > div.brief-download-wrap > a'
                                )[0]['href'].to_s
    lower_check           = doc.css('div.inside-page-section > div.container.inside-pg-content-container > div ' \
                                    '> main > div > div > div.case-details-main-content-wrapper.main-content-wrapper ' \
                                    '> div:nth-child(3) > h2'
                                    ).text.squish
    judge_name            = nil
    lower_court_id        = nil
    lower_case_id         = nil
    lower_judgement_date  = nil
    lower_link            = nil
    disposition           = nil

    if lower_check == 'Court of Appeals'
      lower_court_id = @lower_court
      lower_case_id  = case_id[:case_id]
    end

    case_party_div      = doc.css('div.case-details-section-wrapper')[0]
    case_activities_div = doc.css('div.case-details-section-wrapper')[1]

    case_party = []
    case_party = get_case_party(case_party_div)

    case_activities = []
    case_activities = get_case_activity(case_activities_div)

    pdf_aws = case_activities.slice(0..-1)

    case_pdf_on_aws = []
    case_pdf_on_aws = get_case_pdf_on_aws(pdf_aws)

    {
      :case_id                => case_id[:case_id],
      :case_name              => case_name,
      :case_filed_date        => case_filed_date,
      :case_type              => case_type,
      :case_description       => case_description,
      :disposition_or_status  => disposition_or_status,
      :opinion_link           => opinion_link,
      :judge_name             => judge_name,
      :lower_court_id         => lower_court_id,
      :lower_case_id          => lower_case_id,
      :lower_judgement_date   => lower_judgement_date,
      :lower_link             => lower_link,
      :disposition            => disposition,
      :case_party             => case_party,
      :case_activities        => case_activities,
      :case_pdf_on_aws        => case_pdf_on_aws
    }
  end
  
  def get_case_party(case_party_div)
    case_party = []
    is_lawyer  = 0

    case_party_div.css("h4").each do |item|
      party_type = item.text.squish
      list_party_name = item.next_element.content.split(/<br>/)
      list_party_name = item.next_element.to_s.split(/<br>/, -1) if item.next_element.to_s.include?("<br>")
      list_party_name.each do |name|
        name.slice!(/\<(.*?)\>/)
        next if name.strip.empty?
        data = {
          'is_lawyer'  => is_lawyer/2,
          'party_type' => party_type,
          'party_name' => name.strip
        }
        case_party << data
      end
      is_lawyer += 1
    end

    case_party
  end
  
  def get_case_activity(case_activities_div)
    case_activities = []
    check_brief     = false
    check_opition   = false

    case_activities_div.css('h4').each do |item|
      check_brief   = true if item.text.squish == 'Briefs'
      check_opition = true if item.text.squish == 'Supreme Court Opinion'
    end

    if check_brief 
      activity_date = case_activities_div.css('p')[1]
                        .text.squish
      list_files    = case_activities_div.css('div.brief-downloads-outer-wrap > div.brief-download-wrap')
      list_files.each do |item|
        activity_type = item.css('a').text.squish.split(/\(/, 2)[0].squish
        files         = item.css('a @href').text.squish

        hash = {
                  'activity_date' => activity_date,
                  'activity_type' => activity_type,
                  'file'          => BASE_URL + files
               }
        case_activities << hash
      end
    end

    if check_opition 
      activity_date = case_activities_div.css('div.info-item-space-after > div.inline-text-block')
                        .text.squish
      activity_type = 'Opinion'
      files         = case_activities_div.css('div.brief-download-wrap > a @href').last
                        .text.squish
      
      hash = {
                'activity_date' => activity_date,
                'activity_type' => activity_type,
                'file'          => BASE_URL + files
             }
      
      case_activities << hash
    end

    case_activities
  end
  
  def get_case_pdf_on_aws(pdf_aws)
    case_pdf_on_aws = []
    pdf_aws.each do |item|
      data = {
        'source_type' => 'activity',
        'source_name' => item['activity_type'],
        'source_link' => item['file'],
        'aws_html_link' => nil
      }
      case_pdf_on_aws << data
    end
    case_pdf_on_aws
  end

end