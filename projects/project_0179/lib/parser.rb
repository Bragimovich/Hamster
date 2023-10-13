# frozen_string_literal: true

class Parser < Hamster::Parser
  def disclaimer(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    disclaimer = parsed_doc.at_xpath("//form[@id='frmCasesearchdisclaimer']//td//input[@name='disclaimer']/@value")
    disclaimer.value
  end

  def search_type(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    search = parsed_doc.at_xpath("//form[@name='inquiryForm']//input[@name='searchtype']/@value")
    search.value
  end

  def parse_first_page(search_response_body)
    parsed_doc = Nokogiri::HTML.parse(search_response_body)
    item_text = parsed_doc.at_xpath("//span[@class='pagebanner']/text()")
    if item_text
      if item_text.text.include?('One item found')
        items_count = 1
      else
        match = item_text.text.match(/^(\d*)\s/)
        items_count = match[1].to_i
      end
    else
      items_count = 0
    end
    page_links = 
      if parsed_doc.at_xpath("//span[@class='pagelinks']")
        parsed_doc.at_xpath("//span[@class='pagelinks']")
                  .xpath("./a[@href][not(contains(text(), 'Next'))][not(contains(text(), 'Last'))]")
                  .map(&:values)
                  .map(&:first)
      else
        []
      end
    [items_count, parsed_doc.xpath("//table[@class='results']//tbody//tr//td//a/@href").map(&:value), page_links]
  end

  def parse_items(response_body)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    parsed_doc.xpath("//table[@class='results']//tbody//tr//td//a/@href").map(&:value)
  end

  def parse_case_info(response_body, case_page_url)
    parsed_doc = Nokogiri::HTML.parse(response_body)
    @case_page_url = case_page_url
    add_infos  = []
    hash       = {}
    hash[:case_info] = case_info_block(parsed_doc)
    additional_infos(parsed_doc).each do |info|
      additional_hash = {
        court_id: @court_id,
        case_id: @case_id,
        lower_case_id: info,
        data_source_url: @case_page_url
      }
      add_infos << additional_hash.merge(md5_hash: md5_hash(additional_hash))
    end
    hash[:additional_infos] = add_infos
    hash[:doc_infos] = doc_infos(parsed_doc)
    hash[:party_infos] = party_blocks(parsed_doc)
    hash[:judgment_info] = parse_judge(parsed_doc)
    hash
  end

  def case_info_block(parsed_doc)
    hash = { data_source_url: @case_page_url }
    tr = parsed_doc.at_xpath("//td//span[contains(text(), 'Court System:')]/../..")
    court_system = tr.text.split("\n").map(&:strip).join(" ").split(":").last.strip
    @court_id = court_id(court_system)
    hash[:court_id] = @court_id

    tr = parsed_doc.at_xpath("//tr//td//span[contains(text(), 'Case Number:')]/../..")
    case_number = value_from_spans(tr, 'Case Number')
    @case_id = case_number
    hash[:case_id] = @case_id

    tr = parsed_doc.at_xpath("//tr//td//span[contains(text(), 'Title:')]/../..")
    hash[:case_name] = value_from_spans(tr, 'Title') if tr
    tr = parsed_doc.at_xpath("//tr//td//span[contains(text(), 'Case Type:')]/../..")
    hash[:case_type] = value_from_spans(tr, 'Case Type') if tr
    tr = parsed_doc.at_xpath("//tr//td//span[contains(text(), 'Filing Date:')]/../..")
    filing_date = value_from_spans(tr, 'Filing Date') if tr
    unless tr
      tr = parsed_doc.at_xpath("//tr//td//span[contains(text(), 'Issued Date:')]/../..")
      filing_date = value_from_spans(tr, 'Issued Date') if tr
    end
    hash[:case_filed_date] = Date.strptime(filing_date, '%m/%d/%Y')
    tr = parsed_doc.at_xpath("//tr//td//span[contains(text(), 'Status:')]/../..")
    hash[:status_as_of_date] = value_from_spans(tr, 'Status') if tr
    hash[:lower_case_id] = additional_infos(parsed_doc).join('; ')
    hash.merge(md5_hash: md5_hash(hash)) 
  end

  def additional_infos(parsed_doc)
    reserved_words = %w[parties appellant appellee plaintiff hearing petitioner attorney defendant respondent person causes amicus related clerk]
    data   = []
    st_ind = 0
    ed_ind = 0
    body = parsed_doc.at_xpath("//div[contains(@class, 'BodyWindow')]")
    row_data = body.xpath(".//h5|.//h6|.//span[contains(@class, 'Prompt')]/../..|.//hr|.//tr/td/br")
    row_data.each_with_index do |tb, ind|
      if tb.text.include?('Other Reference Numbers')
        st_ind = ind + 1
      elsif st_ind > 0 && reserved_words.map{|word| tb.text.downcase.include?(word)}.any?
        ed_ind = ind - 1
        break
      end
    end
    row_data[st_ind..ed_ind].each do |tb|
      data << tb.at_xpath(".//span[@class='Value']")&.text
    end
    data.compact.uniq
  end

  def doc_infos(parsed_doc)
    doc_data = []
    doc_info_block = parsed_doc.xpath("//td//span[contains(text(), 'File Date:')]/../../..")
    doc_info_block.each do |doc_body|
      next unless doc_body.at_xpath("./tr//span[contains(text(), 'Document Name:')]/../..//td/span[@class='Value']")
  
      file_date = doc_body.at_xpath("./tr//span[contains(text(), 'File Date:')]/../..//td/span[@class='Value']").text
      hash = {
        court_id: @court_id,
        case_id: @case_id,
        data_source_url: @case_page_url,
        activity_date: Date.strptime(file_date, '%m/%d/%Y'),
        activity_type: doc_body.at_xpath("./tr//span[contains(text(), 'Document Name:')]/../..//td/span[@class='Value']")&.text,
        activity_desc: doc_body.at_xpath("./tr//span[contains(text(), 'Comment:')]/../../td//span[@class='Value']")&.text
      }
      doc_data << hash.merge(md5_hash: md5_hash(hash))
    end
    doc_data.compact.uniq
  end
  
  def party_blocks(parsed_doc)
    start_block = false
    block_array = []
    st_block = 0
    ed_block = 0
    party_type = nil
    reserved_words = %w[appellant appellee hearing plaintiff petitioner attorney defendant respondent person amicus related clerk]
    body = parsed_doc.at_xpath("//div[contains(@class, 'BodyWindow')]")
    row_data = body.xpath(".//h5|.//h6|.//span[contains(@class, 'Prompt')]/../..|.//hr|.//tr/td/br")
    row_data.each_with_index do |el, ind|
      if start_block == false && (el.name == 'h5' || el.name == 'h6')
        if reserved_words.map{|word| el.text.downcase.include?(word)}.any?
          party_type = el.text.strip
          st_block = ind + 1
          start_block = true
        end
      elsif start_block == true && (el.name == 'h5' || el.name == 'h6' || el.name == 'hr' || el.name == 'br')
        ed_block = ind - 1
        start_block = false
        block_array << { type: party_type, el: row_data[st_block..ed_block] }
        if el.name == 'hr' || el.name == 'br' || reserved_words.map{|word| el.text.downcase.include?(word)}.any?
          party_type = el.text.strip if reserved_words.map{|word| el.text.downcase.include?(word)}.any?
          st_block = ind + 1
          start_block = true
        end
      end

      break if el.name == 'h5' && el.text.downcase.include?('document')
    end

    block_array.map { |block| parse_block(block) }.compact.uniq
  end
  
  def parse_block(block)
    party_type = block[:type].gsub("\t", '').gsub("\n", ' ').strip
    party_block = block[:el]

    return if party_block.count.zero?

    spans = []
    hash = {
      data_source_url: @case_page_url,
      court_id: @court_id,
      case_id: @case_id,
      is_lawyer: false
    }
    party_block.each do |tr|
      spans << tr.xpath(".//span").map(&:text).each_slice(2).to_a
    end
    spans = spans.flatten(1)
    spans.each_with_index do |span, ind|
      span[0] = spans[ind-1][0] if span[0] == ''
    end
    type = value_from_spans(spans, 'type') || value_from_spans(spans, 'connection')
    hash[:party_type] = (type || party_type).split(' ').join(' ')
    if hash[:party_type].downcase.include?('attorney')
      hash[:is_lawyer] = true
    end
    hash[:party_name] = value_from_spans(spans, 'name')
    hash[:party_address] = value_from_spans(spans, 'address')
    hash[:party_city] = value_from_spans(spans, 'city')
    hash[:party_state] = value_from_spans(spans, 'state')
    hash[:party_zip] = value_from_spans(spans, 'zip')
    if value_from_spans(spans, 'appearance date')
      hash[:party_description] = "Appearance Date: #{value_from_spans(spans, 'appearance date')}"
      hash[:is_lawyer] = true
    end
    hash.merge(md5_hash: md5_hash(hash)) 
  end

  def parse_judge(parsed_doc)
    hash = {
      data_source_url: @case_page_url,
      court_id: @court_id,
      case_id: @case_id
    }
    tr = parsed_doc.xpath("//tr//td//span[contains(text(), 'Judgment Against:')]/../..")
    hash[:party_name] = value_from_spans(tr, 'Judgment Against')
    tr = parsed_doc.xpath("//tr//td//span[contains(text(), 'Principal Amount:')]/../..")
    hash[:fee_amount] = value_from_spans(tr, 'Principal Amount')
    tr = parsed_doc.xpath("//tr//td//span[contains(text(), 'Amount of Judgment:')]/../..")
    hash[:judgment_amount] = value_from_spans(tr, 'Amount of Judgment')
    tr = parsed_doc.xpath("//tr//td//span[contains(text(), 'Judgment Ordered Date:')]/../..")
    hash[:judgment_date] = value_from_spans(tr, 'Judgment Ordered Date')
    hash.merge(md5_hash: md5_hash(hash)) 
  end

  private

  def value_from_spans(el, key)
    value = nil
    addresses = []
    spans = el.kind_of?(Array) ? el : el.xpath(".//span").map(&:text).each_slice(2).to_a
    spans.each do |span|
      if key == 'address'
        addresses << span[1] if span[0].downcase.include?(key.downcase)
        value = addresses.join(', ')
      else
        value = span[1] if span[0].downcase.include?(key.downcase)
      end
    end
    value
  end

  def court_id(court_system)
    circuit_court_ids = {
      "allegany county": 157,
    	"anne arundel county": 158,
    	"baltimore city": 159,
    	"baltimore county": 160,
    	"calvert county": 161,
    	"caroline county": 162,
    	"carroll county": 163,
    	"cecil county": 164,
    	"charles county": 165,
    	"dorchester county": 166,
    	"frederick county": 167,
    	"garrett county": 168,
    	"harford county": 169,
    	"howard county": 170,
    	"kent county": 171,
    	"montgomery county": 172,
    	"prince george's county": 173,
    	"queen anne's county": 174,
    	"saint mary's county": 175,
    	"somerset county": 176,
    	"talbot county": 177,
    	"washington county": 178,
    	"wicomico county": 179,
    	"worcester county": 180
    }
    district_court_ids = {
	    "allegany county": 133,
	    "anne Arundel county": 134,
	    "baltimore city": 135,
	    "baltimore county": 136,
	    "calvert county": 137,
	    "caroline county": 138,
	    "carroll county": 139,
	    "cecil county": 140,
	    "charles county": 141,
	    "dorchester county": 142,
	    "frederick county": 143,
	    "garrett county": 144,
	    "harford county": 145,
	    "howard county": 146,
	    "kent county": 147,
	    "montgomery county": 148,
	    "prince george's county": 149,
	    "queen anne's county": 150,
	    "saint mary's county": 151,
	    "somerset county": 152,
	    "talbot county": 153,
	    "washington county": 154,
	    "wicomico county": 155,
	    "worcester county": 156
    }
    match = court_system.match(/\sfor\s(\w.*\s(?:city|county))/i)
    county = match[1].downcase if match
    if court_system.include?('Appellate Court of Maryland')
      53
    elsif court_system.include?('Court of Special Appeals')
      58
    elsif court_system.include?('Supreme Court of Maryland')
      59
    elsif court_system.downcase.include?('circuit court')
      circuit_court_ids[county.to_sym]
    elsif court_system.downcase.include?('district court')
      district_court_ids[county.to_sym]
    end
  end

  def md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
