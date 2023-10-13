# frozen_string_literal: true

class Georgia_Parser < Hamster::Parser

  def parse_data(body,run_id,md5_offender,md5_offenses)
    document = parse_page(body)
    get_offender_offenses_data(document,run_id,md5_offender,md5_offenses)
  end

  private

  def parse_page(body)
    Nokogiri::HTML(body.force_encoding("utf-8"))
  end

  def name_split(full_name)
    name_spliting = full_name.split(' ') rescue nil
    return ['','',''] if name_spliting.nil?
    if name_spliting.count == 2
      first_name = name_spliting[1]
      middle_name = nil
      last_name = name_spliting[0].gsub(",","")
    elsif name_spliting.count == 3
      first_name = name_spliting[1]
      middle_name = name_spliting[2]
      last_name = name_spliting[0].gsub(",","")
    elsif name_spliting.count == 1  
      first_name = name_spliting[0]
      middle_name = nil
      last_name = nil 
    elsif name_spliting.count == 4 || name_spliting.count == 5
      first_name = name_spliting[1..-2].join(" ")
      middle_name = name_spliting[-1]
      last_name = name_spliting[0]
    end 
    [first_name,middle_name,last_name]
  end

  def value_check(value)
    value = value.to_s
    if (value.nil?) || (value == "NULL")
      value = '-'
    elsif value.to_i != 0
      return value
    elsif value.strip.empty?
      value = '-'
    end  
    value
  end

  def date_value_check(value)
    value = '1234-12-12' if (value.nil?) || (value == "NULL")
    value
  end

  def hash_generator(data_hash)
    columns_str = ""
    data_hash.keys.each do |key|
      if (key.include? 'date')
        columns_str += date_value_check(data_hash[key]).to_s
      else
        columns_str += value_check(data_hash[key]).to_s
      end
    end
    Digest::MD5.hexdigest columns_str
  end

  def get_values(page,css_selector,search_text)
    values = page.css(css_selector).select{|e| e.text.include? search_text}
    unless values.empty?
      if (search_text == 'NAME:') || (search_text == 'GDC ID:') || (search_text == 'CASE NO:')
        return values[0].text.gsub(search_text,'').squish
      else
        if (css_selector == 'strong')
          return values[0].next_sibling.text.squish
        else
          return values[0].text.gsub(search_text, '').squish
        end
      end
    else
      nil
    end
  end

  def get_sentence_records(gdc_ID,all_elements,sentences_array,sentence_type,run_id)
    all_elements.each do |element|
      data_hash = {}
      data_hash["gdc_ID"] = gdc_ID
      data_hash["sentence_type"] = sentence_type
      data_hash["case_number"] = element.text.gsub('CASE NO:','').squish
      data_hash["offense"] = get_values(element.next_element, 'strong', 'OFFENSE:')
      data_hash["conviction_county"] = get_values(element.next_element, 'strong', 'CONVICTION COUNTY:')
      data_hash["crime_commit_date"] = DateTime.strptime(get_values(element.next_element, 'strong', 'CRIME COMMIT DATE:'), "%m/%d/%Y") rescue nil
      data_hash["sentence_length"] = get_values(element.next_element, 'strong', 'SENTENCE LENGTH:')
      md5hash = hash_generator(data_hash)
      data_hash["md5_hash"] = md5hash
      data_hash["year"] = Date.today.year.to_s
      data_hash["pl_gather_task_id"] = 175772201
      data_hash["run_id"] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      sentences_array << data_hash
    end
    sentences_array
  end

  def get_sentences(page,sentences_array,gdc_ID,run_id)
    if (page.css('h6').select{|e| e.text.include? 'CURRENT SENTENCES'}.count != 0)
      if (page.css('h6').select{|e| e.text.include? 'PRIOR SENTENCES'}.count != 0)
        start_tag = page.css('h6').select{|e| e.text.include? 'CURRENT SENTENCES'}.first.to_s
        last_tag = page.css('h6').select{|e| e.text.include? 'PRIOR SENTENCES'}.first.to_s
        first_split = page.to_s.split(start_tag)[-1]
        exact_match = first_split.split(last_tag)[0]
        parsed_tag = parse_page(exact_match)
        all_elements = parsed_tag.css('h7')
        sentences_array = get_sentence_records(gdc_ID, all_elements, sentences_array, 'CURRENT',run_id)
        prior_split = page.to_s.split(last_tag)[-1]
        parsed_tag = parse_page(prior_split)
        all_elements = parsed_tag.css('h7')
        sentences_array = get_sentence_records(gdc_ID, all_elements, sentences_array, 'PRIOR',run_id)
      else
        puts "No Prior Sentence Found"
      end
    else
      puts "No Current Sentence FOUND"
    end
    sentences_array
  end

  def get_offender_offenses_data(page,run_id,md5_offender,md5_offenses)
    data_array = []
    sentences_array = []
    data_hash = {}

    return [data_array,sentences_array] if (page.text.include? 'Sorry, we couldn\'t find any offender records')

    full_name = get_values(page, 'h4', "NAME:")
    data_hash["full_name"] = full_name
    data_hash["first_name"], data_hash["middle_name"], data_hash["last_name"] =  name_split(full_name)

    data_hash["gdc_ID"] = get_values(page, 'h5', "GDC ID:")
    data_hash["year_of_birth"] = get_values(page, 'strong', "YOB:")
    data_hash["race"] = get_values(page, 'strong', "RACE:")
    data_hash["gender"] = get_values(page, 'strong', "GENDER:")

    data_hash["height"] = get_values(page, 'strong', "HEIGHT:")
    data_hash["weight"] = get_values(page, 'strong', "WEIGHT:")
    data_hash["eye_color"] = get_values(page, 'strong', "EYE COLOR:")
    data_hash["hair_color"] = get_values(page, 'strong', "HAIR COLOR:")

    data_hash["alien_no"] = nil
    data_hash["alien_no"] = get_values(page, 'p', "ALIEN NO:") unless (get_values(page, 'p', "ALIEN NO:").nil?)

    data_hash["major_offense"] = get_values(page, 'strong', "MAJOR OFFENSE:")
    data_hash["most_recent_institution"] = get_values(page, 'strong', "MOST RECENT INSTITUTION:")

    max_release_date = get_values(page, 'strong', "MAX POSSIBLE RELEASE DATE:")
    data_hash["max_possible_release_date"] = DateTime.strptime(max_release_date, "%m/%d/%Y") rescue max_release_date

    actual_release = get_values(page, 'strong', "ACTUAL RELEASE DATE:")
    if (actual_release == "CURRENTLY SERVING")
      data_hash["actual_release_date"] = actual_release
    else
      data_hash["actual_release_date"] = DateTime.strptime(actual_release, "%m/%d/%Y")
    end

    data_hash["current_status"] = get_values(page, 'strong', "CURRENT STATUS:")
    data_hash["md5_hash"] = hash_generator(data_hash)

    data_hash["year"] = Date.today.year.to_s

    if page.css('h5').select{|e| e.text.include? 'KNOWN ALIASES'}.count != 0
      aliases_values = page.css('h5').select{|e| e.text.include? 'KNOWN ALIASES'}.first
      data_hash["aliases"] = aliases_values.next_element.css('strong').map{|e| e.next_sibling.text.squish}.join(" | ")
    else
      data_hash["aliases"] = nil
    end

    data_hash["run_id"] = run_id
    data_hash["pl_gather_task_id"] = 175772201
    data_hash["last_scrape_date"] = "#{Date.today}"
    data_hash["next_scrape_date"] = "#{Date.today.next_month}"

    data_hash = mark_empty_as_nil(data_hash)
    data_array << data_hash

    sentences_array = get_sentences(page,sentences_array,data_hash["gdc_ID"],run_id)

    data_array = delete_md5_key(reject_existing_data(data_array,md5_offender),'md5_hash')
    sentences_array = delete_md5_key(reject_existing_data(sentences_array,md5_offenses),'md5_hash')

    [data_array,sentences_array]
  end

  def reject_existing_data(data_array,md5_array)
    data_array.reject{|e| md5_array.include? e[:md5_hash]}
  end

  def delete_md5_key(data_array,key)
    data_array.each{|data_hash| data_hash.delete(key)} unless data_array.empty?
    data_array
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == '-') ? nil : value}
  end
end
