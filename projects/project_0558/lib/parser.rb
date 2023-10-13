# frozen_string_literal: true

require_relative '../lib/scraper'

class Parser < Hamster::Parser
  attr_reader :all_info_hash

  def initialize
  end 
  
  def html=(doc)
    @html = Nokogiri::HTML5(doc.force_encoding("utf-8"))
  end

  def list_links(year = Date.today.year)
    pdf_links_info = []
    @html.css('a').each do |el| 
      pdf_info = {}
      if el.attribute('href') && el.attribute('href')&.value.include?("/apps-courts-epub/public/viewAdvanced")
        pdf_info[:link] = Scraper::ROOT_LINK_PREFIX + el.attribute('href') 
        tds = el.parent.parent.xpath('td')
        pdf_info[:date] = tds[0].text.strip
        pdf_info[:case_id] = tds[1].text.strip
        if !pdf_info[:case_id].nil?
          pdf_info[:case_id] = pdf_info[:case_id].gsub(/\n\t\s+/, ",")
        end
        pdf_info[:case_name] = tds[2].text.strip
        pdf_info[:citation] = tds[3].text.strip
        if pdf_info[:date].split("/")[-1] == year.to_s
          pdf_links_info.push(pdf_info)
        end
      end
    end
    pdf_links_info
  end

  def parse_pdf_links_328(content)
    
    page = Nokogiri::HTML(content)    
    links = []
    pdf_links_info = []
    page.css('a').each do |el| 
      pdf_info = {}
      if el.attribute('href') && el.attribute('href')&.value.include?("/apps-courts-epub/public/viewAdvanced")
        pdf_info[:link] = Scraper::ROOT_LINK_PREFIX + el.attribute('href') 
        tds = el.parent.parent.xpath('td')
        pdf_info[:date] = tds[0].text.strip
        pdf_info[:case_id] = tds[1].text.strip
        pdf_info[:case_name] = tds[2].text.strip
        pdf_info[:citation] = tds[3].text.strip
        pdf_links_info.push(pdf_info)
      end
    end
    pdf_links_info
  end

  def parse_pdf_links_445(content)
    
    page = Nokogiri::HTML(content)    
    links = []
    pdf_links_info = []
    page.css('a').each do |el| 
      pdf_info = {}
      if el.attribute('href') && el.attribute('href')&.value.include?("/apps-courts-epub/public/viewAdvanced")
        pdf_info[:link] = Scraper::ROOT_LINK_PREFIX + el.attribute('href') 
        tds = el.parent.parent.xpath('td')
        pdf_info[:date] = tds[0].text.strip
        pdf_info[:case_id] = tds[1].text.strip
        pdf_info[:case_name] = tds[2].text.strip
        pdf_info[:citation] = tds[3].text.strip
        pdf_links_info.push(pdf_info)
      end
    end
    pdf_links_info
  end
  
  def get_case_info(pdf_content)
    # puts "Call get_case_info ...".green
    result = {}
    main_paragraph = get_lawyer_paragraph(pdf_content)
    sentences = get_sentences(main_paragraph)
    sentences.each do |sentence |
      sentence = sentence.strip.gsub(/\n/, "\t") + '.'
      st_date = get_status_as_of_date(sentence)
      unless st_date.nil?
        if result[:status_as_of_date].nil? || result[:status_as_of_date].empty?
          result[:status_as_of_date] = get_pretty_name(st_date)
        end
      end
      judge_name = get_judge_name(sentence)
      unless judge_name.nil?
        if result[:judge_name].nil? || result[:judge_name].empty?
          result[:judge_name] = get_pretty_name(judge_name)
        end
      end
    end
    result
  end
  
  # get_case_party() returns array of case party object
  def get_case_party(pdf_content)
    # puts "Starting get_case_party() ...".green
    result = []
    main_paragraph = get_lawyer_paragraph(pdf_content)
    # puts main_paragraph.inspect
    sentences = get_sentences(main_paragraph)    
    # puts "Lawyer Paragraph Analyzing ", sentences.inspect.green
    sentences.each do |sentence |
      sentence = sentence.strip.gsub(/\n/, "\t") + '.'
      record = {}
      if record[:party_name].nil? || record[:party_name].empty?
        party_name = get_party_name(sentence, 'appellee')
        unless party_name.nil?
          record[:is_lawyer] = 1
          record[:party_name] = get_pretty_name(party_name)
          record[:party_type] = 'Attorney for appellee'
          record[:party_description] = sentence
          result.push(record)
        end
        party_name = get_party_name(sentence, 'appellant')
        unless party_name.nil?
          record[:is_lawyer] = 1
          record[:party_name] = get_pretty_name(party_name)
          record[:party_type] = 'Attorney for appellant'
          record[:party_description] = sentence
          result.push(record)
        end
      end
    end

    main_paragraph = get_no_lawyer_paragraph(pdf_content)
    sentences = get_sentences(main_paragraph)
    sentences.each do |sentence |
      sentence = sentence.strip.gsub(/\n/, '\t') + '.'
      record = {}
      if record[:party_name].nil? || record[:party_name].empty?
        party_name = get_party_name_no_lawyer(sentence, 'appellee')
        unless party_name.nil?
          record[:is_lawyer] = 0
          record[:party_name] = get_pretty_name(party_name)
          record[:party_type] = 'appellee'
          record[:party_description] = sentence
          result.push(record)
        end
        party_name = get_party_name_no_lawyer(sentence, 'appellant')
        unless party_name.nil?
          record[:is_lawyer] = 0
          record[:party_name] = get_pretty_name(party_name)
          record[:party_type] = 'appellant'
          record[:party_description] = sentence
          result.push(record)
        end
      end
    end
    result
  end 

  def get_additional_info(pdf_content)
    result = {}
    main_paragraph = get_lawyer_paragraph(pdf_content)
    sentences = get_sentences(main_paragraph)
    sentences.each do | sec |
      
      if result[:lower_judge_name].nil?
        judge_name = get_lower_judge_name(sec)
        unless judge_name.nil?
          result[:lower_judge_name] = judge_name
        end
      end
      if result[:lower_court_name].nil?
        court_name = get_lower_court_name(sec)
        unless court_name.nil?
          result[:lower_court_name] = court_name
        end
      end
    end
    return result
  end

  def get_case_activities(pdf_content)
    result = {}
    main_paragraph = get_no_lawyer_paragraph(pdf_content)
    sentences = get_sentences(main_paragraph)
    sentences.each do |sentence |
      sentence = sentence.strip.gsub(/\n/, '\t') + '.'
      matches = sentence.scan(/Filed (.*?)(?=\.)./)
      unless matches.flatten.empty?
        date_str = matches[0][0].strip
        d = DateTime.parse(date_str)
        result[:activity_date] = d.strftime('%Y-%m-%d')
      end
    end
    return result
  end

  # party_type: appellee, appellant when is_lawyer=1 
  def get_party_name(sentence, party_type)
    if sentence.include?(party_type)
      new_sentence = sentence.gsub(/\n\t*{[A-Z]}/, "\t\\1")
      matches = new_sentence.scan(/(.*)for[\s|\t]*#{party_type}/)
      unless matches.flatten.empty?
        rlt = matches[0][0].strip 
        rlt[-1] = '' if rlt[-1] == ','
        return rlt
      end
    end
    return nil
  end

  # party_type: appellee, appellant when is_lawyer=0
  def get_party_name_no_lawyer(sentence, party_type)
    if sentence.include?(party_type)
      new_sentence = sentence.gsub(/\s{4,}/, "\n")
      matches = new_sentence.scan(/(.*)#{party_type}/)
      unless matches.flatten.empty?
        rlt = matches[0][0].strip 
        rlt[-1] = '' if rlt[-1] == ',' || rlt[-1] == ' '
        return rlt
      end
    end
    return nil
  end

  def get_judge_name(sentence)
    if !sentence.downcase.include?("appellee") && !sentence.downcase.include?("appellant") && !sentence.downcase.include?('district court')
      return sentence.strip if sentence.include?("C.J") || sentence.include?(", JJ")
    end
    return nil
  end
  def get_status_as_of_date(sentence)    
    matches = sentence.scan(/(affirmed .*)\./i)
    matches = sentence.scan(/(affirmed)\./i) if matches.flatten.empty?
    return matches[0][0].strip unless matches.flatten.empty?
    return nil
  end

  def get_lower_judge_name(sentence)
    if sentence.scan(/judge/i).empty?
      return nil 
    end
    result = ""
    judge_names = []
    new_sentence = sentence.gsub(/\n/, "\t")
    new_sentence = new_sentence.gsub(/(judge[s|\.|,]*)/i, "\\1__SPLIT__")
    
    sec_arr = new_sentence.split("__SPLIT__")

    sec_arr.each do |sec|
      matches = sec.scan(/[,|:]+(.*),[\t|\s]Chief Judge/)
      sec = sec.gsub(/\t/, " ")
      unless matches.flatten.empty?
        judge_names.push(matches[0][0].strip)
      else
        # matches = sec.scan(/[,|:]?[\t|\s](.*),[\t|\s]Judge/)
        matches = sec.scan(/(?:[,|:])[\t|\s]+(.*),[\t|\s]Judge/)
        if matches.flatten.empty?
          matches = sec.scan(/(.*),[\t|\s]Judge/)
        end
        unless matches.flatten.empty?
          judge_names.push(matches[0][0].strip)
        end
      end
    end
    judge_names.join(', ')
  end
  def get_lower_court_name(sentence)
    new_sentence = sentence.gsub(/\n/, " ").gsub(/\t/, ' ').gsub('  ', ' ')
    matches = new_sentence.scan(/from (the .* Court for .*?)(?=[:|,])[:|,]/i)
    if matches.flatten.empty?
      matches = new_sentence.scan(/from (the .*Court of .*?)(?=[:|,])[:|,]/i)
    end

    return matches[0][0].strip unless matches.flatten.empty?
    return nil
  end
  
  def get_lawyer_paragraph(pdf_content)
    stop_words = ['jj.', 'introduction', 'nature of case', 'background', 'i.']
    to_index = nil
    stop_word = stop_words[0]
    stop_words.each do |wd|
      to_index = pdf_content.downcase.index(wd)
      stop_word = wd
      break unless to_index.nil?
    end
    paragraph = ''
    unless to_index.nil?
      if stop_word == 'jj.'
        last_sentence = pdf_content.scan(/JJ..*\n*/i)[0]
        to_index = pdf_content.downcase.index(last_sentence.downcase)
        to_index = to_index + last_sentence.length - 1
        first_paragraph = pdf_content.slice(0..to_index-1)
      else
        first_paragraph = pdf_content.slice(0..to_index-1)
      end
      num = 1
      loop do
        break if first_paragraph.scan(/\n\s*#{num}./).empty?
        num = num + 1
      end
      num = num - 1
      
      return first_paragraph if num == 0
      matches = first_paragraph.scan(/\n\s*#{num}./)
      sentence = matches[0]
      start_index = first_paragraph.downcase.index(sentence.downcase)
      paragraph = first_paragraph.slice(start_index..-1)
      start_index = paragraph.index(/\.\n\n/)
      if start_index.nil?
        start_index = paragraph.index(/\n\n\n/)
      end
      start_index = 0 if start_index.nil?
      paragraph = paragraph.slice(start_index+1..-1)
    end
    paragraph
  end

  
  def get_no_lawyer_paragraph(pdf_content)

    paragraph = ''
    to_index = pdf_content.index("1.")
    unless to_index.nil?
      paragraph = pdf_content.slice(0..to_index)
    else
      paragraph = pdf_content
    end
    paragraph
  end
  def get_sentences(pdf_content)
    content = pdf_content
    while !content.nil? && content[0] == "\n"
      content[0] = ''
    end

    content = pdf_content.gsub(/(\.\n\n+)(\s{2,}[A-Z])/, "\\1__NEW_LINE__\\2")
    sentences = content.split("__NEW_LINE__")
    sentences.each_with_index do |sec, index|
      sentences[index] = sec.gsub(/^[\s|\n]+\n/, "")
    end
    sentences.each_with_index do |sec, index|
      if !sec.nil? && sec.scan(/court/i).empty? && sec.scan(/Affirmed/i).empty? && 
        sec.scan(/appellant/i).empty? && sec.scan(/appellee/i).empty? && 
        sec.scan(/C.J/i).empty? && sec.scan(/JJ/i).empty?
        if index > 0 && index + 1 < sentences.length
          cnt_space = get_space_count_of(sec)
          cnt_space_next = get_space_count_of(sentences[index+1])
          if cnt_space_next + 4 == cnt_space || cnt_space_next + 2 == cnt_space
            sentences[index] = sentences[index] + sentences[index+1]
            sentences[index+1] = nil
          end
        end
      end 
    end
    sentences.compact
  end

  def get_space_count_of(sentence)
    rlt = 0
    i = 0
    while sentence[i] == ' '
      i = i + 1
      rlt = rlt + 1
    end
    return rlt
  end

  def get_pretty_name(name)
    name.gsub(/\t+/, "\t").gsub(/\s+/, " ")[0..253]
  end

end
