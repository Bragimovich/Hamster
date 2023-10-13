# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    super
    @court_id = 84
  end

  def terms_page?(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.at_xpath("//form[@name='TermsForm']")
  end

  def required_captcha?(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    desc = parsed_doc.at_xpath("//span[@id='civilSearchDataNotFound']")
    desc&.text&.include? 'Validate the recaptcha'
  end

  def parse_cases(response_body)
    data = []
    parsed_doc = Nokogiri::HTML.parse(response_body)
    case_data = parsed_doc.xpath("//table[@id='searchResultTable']/tbody/tr/td[@class='result-number']/a")
    case_data.each do |c|
      data << c.text
    end
    data
  end

  def process_page(response_body, case_id)
    @case_id = case_id
    parsed_doc = Nokogiri::HTML.parse(response_body)
    {case_info: parse_case_info(parsed_doc), activity_info: parse_case_activity(parsed_doc)}
  end

  def parse_case_info(parsed_doc)
    data = {court_id: @court_id}
    case_type = ''
    category = ''
    parsed_doc.xpath("//table[@id='caseSummaryData']/tr").reject{|tr| tr.text.blank?}.each do |tr|
      tds = tr.xpath('./td').reject{|td| td.text.blank?}
      if tds[0].text.downcase.include?('case id')
        data[:case_id] = remove_space(tds[1].text)
        @case_id = data[:case_id]
        @data_source_url = "https://civilwebshopping.occourts.org/ShowCase.do?index=0&number=#{@case_id}&tab=0#caseAnchor"
        data[:data_source_url] = @data_source_url
      elsif tds[0].text.downcase.include?('case title')
        data[:case_name] = remove_space(tds[1].text)
      elsif tds[0].text.downcase.include?('filing date')
        data[:case_filed_date] = Date.strptime(remove_space(tds[1].text), '%m/%d/%Y')
      elsif tds[0].text.downcase.include?('case type')
        case_type = remove_space(tds[1].text)
      elsif tds[0].text.downcase.include?('category')
        category = remove_space(tds[1].text)
      end
    end
    data[:case_type] = "#{category}-#{case_type}"
    data[:md5_hash] = create_md5_hash(data)
    data
  end

  def parse_case_activity(parsed_doc)
    data = []
    parsed_doc.xpath("//table[@id='roaData']/tbody/tr").reject{|tr| tr.text.blank?}.each do |tr|
      tds = tr.xpath('./td').reject{|td| td.text.blank?}
      hash_data = {
        court_id: @court_id,
        case_id: @case_id,
        activity_decs: remove_space(tds[1].text),
        activity_date: Date.strptime(remove_space(tds[2].text), '%m/%d/%Y'),
        data_source_url: @data_source_url
      }
      data << hash_data.merge(md5_hash: create_md5_hash(hash_data))
    end
    data
  end

  def parse_case_party(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    data       = []
    header     = parsed_doc.xpath("//table[@id='eservedView']/thead/tr/th").map(&:text)
    party_rows = parsed_doc.xpath("//table[@id='eservedView']/tbody/tr").map{|tr| tr.xpath("./td").map(&:text)}

    party_rows.each do |tr|
      next if tr[0].blank?

      hash_data = {court_id: @court_id, case_id: @case_id, is_lawyer: false, data_source_url: @data_source_url}
      hash_data[:party_name] = tr[0]&.strip
      hash_data[:party_type] = tr[1]&.strip
      data << hash_data.merge(md5_hash: create_md5_hash(hash_data))
    end

    ind = 0
    while ind < party_rows.count do
      tr = party_rows[ind]

      break unless tr

      if tr[3].blank? || tr[3].length < 3
        ind += 1
        next 
      end

      hash_data = {court_id: @court_id, case_id: @case_id, is_lawyer: true, data_source_url: @data_source_url}

      if header[3].downcase.include?('party attorney')
        hash_data[:party_name] = tr[3].strip 
        hash_data[:party_type] = 'Plaintiff Attorney'
      end

      emails = []
      unless tr[4].blank?
        emails << tr[4].strip
        (ind+1..party_rows.count).to_a.each do |row|
          next_tr = party_rows[row]

          break if next_tr.nil?
          break unless next_tr[3].blank?

          emails << next_tr[4] if next_tr[3].blank?
          ind = row
        end
      end
      hash_data[:party_description] = "email: #{emails.join('; ')}"
      data << hash_data.merge(md5_hash: create_md5_hash(hash_data))
      ind += 1
    end 
    data
  end

  private

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end

  def remove_space(str)
    return if str.nil?
    str.strip.split('').reject{|ch| ch.ord == 160}.join
  end
end
