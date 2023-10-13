# frozen_string_literal: true

require_relative '../models/maine_bar'
require_relative '../models/maine_bar_runs'

class MaineBarParser < Hamster::Parser

  # SOURCE = 'https://www1.maine.gov/cgi-bin/online/maine_bar/'
  SOURCE = 'https://apps.web.maine.gov/cgi-bin/online/maine_bar/'

  def initialize(*_)
    super
    @stored_attorney_md5 = collect_stored_attorneys
    @unchanged_attorney = []
    @run_id = nil
    @finished = false
  end

  def start
    send_to_slack "Project #0391 store started"
    log_store_started

    store

    log_store_finished
    send_to_slack "Project #0391 store finished"
  rescue => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack "project_0391 error in start:\n#{e.inspect}"
  end

  private

  def store
    index_folder = @run_id.to_s.rjust(4, "0") + '_indexes'
    index_list = peon.give_list(subfolder: index_folder).sort
    index_list.each do |index_file|
      page = peon.give(subfolder: index_folder, file: index_file)
      index_num = index_file.gsub('.gz', '').split('_')[-1]
      parse_index(page, index_num)
    rescue StandardError => e
      print_all e, e.full_message, title: " ERROR "
      send_to_slack "project_0391 error in store:\n#{e.inspect}"
    end
    update_touched_run_id
    update_delete_status
  end

  def parse_index(file_content, index_num)
    rows = Nokogiri::HTML(file_content).at('#maincontent1 table tbody').css('tr')
    return if rows.empty? || (rows&.first&.at('p')&.attr('class') == 'error')
    records = []
    items_folder = @run_id.to_s.rjust(4, "0") + '_index_' + index_num.to_s.rjust(3, "0")
    files_list = peon.give_list(subfolder: items_folder).to_set
    rows.each_with_index do |item, idx|
      file_name = "#{index_num.to_s.rjust(3, "0")}_#{idx.to_s.rjust(2, "0")}"
      next unless files_list.include? "#{file_name}.gz"
      item_content = peon.give(subfolder: items_folder, file: file_name)
      record = parse_item(item, item_content)
      records.push(record) unless record.nil?
    rescue StandardError => e
      print_all e, e.full_message, title: " ERROR "
      send_to_slack "project_0391 error in parse_index:\n#{e.inspect}"
    end
    MaineBar.insert_all(records) unless records.empty?
  end

  def parse_item(record, record_content)
    page = Nokogiri::HTML(record_content)
    city_state = record.css('td')[1].text.strip
    county = record.css('td')[2].text.strip.presence
    zip	= record.css('td')[3].text.strip
    info = page.at('fieldset').elements.select {|e| e.name == 'ul'}
    rec = {}
    info.each do |i|
      i.elements.each do |e|
        rec[e.children[0]&.text&.strip] = e.children[1]&.text&.strip if e.children[1]&.name == 'strong'
      end
    end
    full_name = rec["Name:"].gsub(/^00|^\.|^\\|^s/,'')
    name_pref_regex = /^(Mr\.|Mrs\.?|Ms\.|Ms|Mx\.|M\.|Dr\.|Hon\.|Lt\. Col\.|Col\.?|Mag\.|Sen\.|Miss|CAPT|CPT\.?|Capt.|Dean|Rev\.|Prof\.|LTC|Cmdr\.|DA|Maj\.|LtCol)/
    name_suf_regex = /,|Esq\.?|Jr\.?|III|II|IV|LCSW|LMSW|AAG|LCPC|LADC|CPA|LSW|LMFT|MS|Sr\.|Ph\.?D\.?|Hon\.|JD|B\.S\.|M\.Ed\.|Psy\.D\.?|P\.A\.|Ms\./
    name_pref = full_name.match(name_pref_regex)&.[](0)
    name = name_pref.nil? ? full_name : full_name.sub(name_pref, '').strip
    name = name.gsub(name_suf_regex, '').strip
    name_parts = name.split
    name_parts[0], name_parts[1] = name_parts[1], name_parts[0] unless name_parts[0].match(/^[A-Z]\.?$/).nil?
    full_address = rec["Address:"].sub('Not available','').strip
    address_parts = full_address.split(',').map{|s| s.strip}
    attorney = {
      run_id:               @run_id,
      touched_run_id:       @run_id,
      bar_number:           rec["Bar Number:"].presence || record.css('td')[4].text.strip.presence,
      name:                 full_name.presence,
      first_name:           name_parts.reverse!.pop,
      last_name:            name_parts.reverse!.pop,
      middle_name:          name_parts.join(' ').strip.presence,
      date_admitted:        (Date.strptime(rec["First Admitted to the Bar:"], '%m/%d/%Y') rescue nil),
      registration_status:  rec["Registration Status:"].presence,
      phone:                rec["Phone:"].presence,
      fax:                  rec["Fax:"].presence,
      law_firm_name:        rec["Firm/Office Name:"].presence,
      law_firm_address:     rec["Address:"]&.strip.presence,
      law_firm_zip:         zip.presence || address_parts.last&.match(/\d{5}-?\d{4}?/)&.[](0),
      law_firm_city:        city_state.split(',')[0]&.strip.presence || address_parts[-2].presence,
      law_firm_state:       city_state.split(',')[1]&.strip.presence || address_parts&.last&.match(/[A-Z]{2}/)&.[](0),
      law_firm_county:      county.presence,
      name_prefix:          name_pref.presence,
      university:           rec["Law School:"].presence,
      law_firm_website:     rec["Website:"].presence, #blocks[1].css('li')[2].at('strong').text.strip.presence
      other_jurisdictions:  parse_jurisdictions(info[2].at('li:contains("Other Jurisdictions:")')),
      data_source_url:      SOURCE + record.at('td a')['href']
    }
    keys = %i[bar_number name first_name last_name middle_name date_admited registration_status phone fax
              law_firm_name law_firm_address law_firm_zip law_firm_city law_firm_state law_firm_county
              name_prefix university law_firm_website other_jurisdictions data_source_url]
    attorney[:md5_hash] = make_md5(attorney, keys)

    if @stored_attorney_md5.include? attorney[:md5_hash]
      @unchanged_attorney.push(attorney[:md5_hash])
      return nil
    end

    attorney
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack "project_0391 error in parse_item:\n#{e.inspect}"
    return nil
  end

  def make_md5(hash, keys)
    values_str = ''
    keys.each { |key| values_str += (hash[key].nil? ? 'nil' : hash[key].to_s) }
    Digest::MD5.hexdigest values_str
  end

  def parse_jurisdictions(node)
    node.css('li').map{|e| e.text.strip}.join('; ').strip.presence
  end

  def collect_stored_attorneys
    MaineBar.where(deleted: 0).pluck(:md5_hash).to_set
  end

  def update_touched_run_id
    MaineBar.where(md5_hash: @unchanged_attorney).update_all(touched_run_id: @run_id)
  end

  def update_delete_status
    MaineBar.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def log_store_started
    last_run = MaineBarRuns.last
    @run_id = last_run.id
    if last_run.status == 'download finished'
      last_run.update(status: 'store started')
      puts "#{"="*50} store started #{"="*50}"
    else
      raise "Scrape has not finished correctly"
    end
  end

  def log_store_finished
    MaineBarRuns.find(@run_id).update(status: 'finished')
    puts "#{"="*50} store finished #{"="*50}"
  end

  def print_all(*args, title: nil, line_feed: true)
    puts "#{"=" * 50}#{title}#{"=" * 50}" if title
    puts args
    puts if line_feed
  end

  def send_to_slack(message)
    Hamster.report(to: 'U031HSK8TGF', message: message)
  end

end
