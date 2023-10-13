# frozen_string_literal: true

require_relative '../models/nm_lawyer_status'
require_relative '../models/nm_lawyer_status_runs'

class NMLawyerStatusParser < Hamster::Parser

  CHUNK = 1000

  def initialize
    super
    @run_id = nil
  end

  def start
    Hamster.report(to: 'Alim Lumanov', message: "Task #0154 store started")
    log_store_started

    bar_members = parse_index
    lawyers = parse_additional_data(bar_members)
    update_and_store(lawyers)

    log_store_finished
    Hamster.report(to: 'Alim Lumanov', message: "Task #0154 store finished")
  rescue => e
    puts e, e.full_message
    Hamster.report(to: 'Alim Lumanov', message: "Task #0154 - start:\n#{e}")
  end

  private

  def parse_index
    index_file = 'index'
    index_folder = @run_id.to_s.rjust(4, "0") + '_index'
    main_page = peon.give(subfolder: index_folder, file: index_file)
    main_doc = Nokogiri::HTML(main_page)

    name_pref_regex = /^(Mr\.|Mrs\.?|Ms\.|Ms|Mx\.|M\.|Dr\.|Hon\.|Lt\. Col\.|Col\.?|Mag\.|Sen\.|Miss|CAPT\.?|CPT\.?|Capt.|Dean|Rev\.|Prof\.|LTC|Cmdr\.|DA|Maj\.|MAJ|Maj|LtCol|Lt Col|The Honorable \(Ret\.\)|1LT|1st Lt|LT|BGen|LCDR) /
    name_suf_regex = /,|Esq\.?|Jr\.?|III|II|IV|LCSW|LMSW|AAG|LCPC|LADC|CPA|LSW|LMFT|MS|Sr\.|Ph\.?D\.?|Hon\.|JD|B\.S\.|M\.Ed\.|Psy\.D\.?|P\.A\.|Ms\./

    rows = main_doc.at('#myTable tbody').css('tr')
    rows.map do |row|
      row.at('span').remove
      bar_number = row.css('td').css('a').last['onclick'].split(',').last.gsub("'", '').gsub(")", '')
      full_name = row.css('td').first.text.squish
      name_pref = full_name.match(name_pref_regex)&.[](0)
      name = name_pref.nil? ? full_name : full_name.sub(name_pref, '').strip
      name = name.gsub(name_suf_regex, '').strip
      name_parts = name.split
      name_parts[0], name_parts[1] = name_parts[1], name_parts[0] unless name_parts[0].match(/^[A-Z]\.?$/).nil?
      date_admitted_str = row.css('td')[4].text.squish.presence
      date_admitted = date_admitted_str && Date.strptime(date_admitted_str, '%m/%d/%Y')
      status = row.css('td')[1].text.squish.presence
      phone = row.css('td')[2].text.squish.presence
      county = row.css('td')[3].text.squish.presence
      link = "https://www.sbnm.org/cvweb/cgi-bin/utilities.dll/customList?QNAME=FINDALAWYER&WHP=none&WBP=LawyerProfilex.htm&customercd=#{bar_number}"
      {
        bar_number: bar_number,
        name: full_name.presence,
        name_prefix: name_pref.presence,
        first_name: name_parts.reverse!.pop,
        last_name: name_parts.reverse!.pop,
        middle_name: name_parts.join(' ').strip.presence,
        registration_status: status,
        date_admitted: date_admitted,
        phone: phone,
        email: nil,
        law_firm_name: nil,
        law_firm_address: nil,
        law_firm_city: nil,
        law_firm_state: nil,
        law_firm_zip: nil,
        law_firm_county: county,
        data_source_url: link
      }
    end
  end

  def parse_additional_data(lawyers)
    link = nil
    files_list = collect_saved_files
    lawyers.each_with_index do |lawyer, idx|
      doc = lawyer_info_page(idx, files_list)
      if (doc.nil? || doc.css('.col-xs-12').empty?)
        lawyer[:md5_hash] = calc_md5_hash(lawyer)
        next
      end
      first_column = doc.css('.col-xs-12').last.elements[0].elements[0]
      law_firm_city_state_zip = first_column.children.last.text
      law_firm_name = parse_law_firm_name(first_column)
      law_firm_street_address = parse_street_address(first_column)
      law_firm_city, law_firm_state, law_firm_zip = parse_city_state_zip(law_firm_city_state_zip)

      second_column = doc.css('.col-xs-12').last.elements[0].elements[1]
      lines = second_column.elements.map { |el| el.text.strip }
      email = lines.find { |l| l.include? "@" }

      lawyer[:law_firm_name] = law_firm_name
      lawyer[:law_firm_address] = law_firm_street_address
      lawyer[:law_firm_city] = law_firm_city
      lawyer[:law_firm_state] = law_firm_state
      lawyer[:law_firm_zip] = law_firm_zip
      lawyer[:email] = email
      lawyer[:md5_hash] = calc_md5_hash(lawyer)
    rescue => e
      puts e, link, e.full_message
      Hamster.report(to: 'Alim Lumanov', message: "Task #154 parse_additional_data\nidx = #{idx}\n#{e}\n#{link}")
    end

    lawyers
  end

  def collect_saved_files
    records_folder = @run_id.to_s.rjust(4, "0") + '_records'
    peon.give_list(subfolder: records_folder).to_set
  end

  def lawyer_info_page(record_num, files_list)
    file_name = "#{record_num.to_s.rjust(5, "0")}"
    return nil unless files_list.include? "#{file_name}.gz"
    records_folder = @run_id.to_s.rjust(4, "0") + '_records'
    page = peon.give(subfolder: records_folder, file: file_name)
    Nokogiri::HTML(page)
  end

  def parse_city_state_zip(law_firm_city_state_zip)
    return if law_firm_city_state_zip.strip.empty?

    unless law_firm_city_state_zip.include?(",")
      return[nil, nil, law_firm_city_state_zip.strip]
    end

    law_firm_city = law_firm_city_state_zip.split(',')[0].strip.presence
    if law_firm_city_state_zip.split(',')[1].split(" ").size == 1
      if law_firm_city_state_zip.split(',')[1].rstrip.include?("  ")
        law_firm_zip = law_firm_city_state_zip.split(',')[1].split(" ")[0]
        law_firm_state = nil
      else
        law_firm_zip = nil
        law_firm_state = law_firm_city_state_zip.split(',')[1].split(" ")[0]
      end
    else
      law_firm_zip = law_firm_city_state_zip.split(',')[1].strip.split(" ", 2)[1]
      law_firm_state = law_firm_city_state_zip.split(',')[1].split(" ")[0]
    end
    [law_firm_city, law_firm_state, law_firm_zip]
  rescue => e
    puts e, e.full_message
    Hamster.report(to: 'Alim Lumanov', message: "Task #154 - parse_additional_data:\n#{e}")
    [nil, nil, nil]
  end

  def parse_street_address(first_column)
    return if first_column.children.last.text.strip.empty? || (first_column.children.css('p').size < 2)
    first_column.children.css('p').last.text.strip
  end

  def parse_law_firm_name(first_column)
    return if first_column.children.last.text.strip.empty? || (first_column.children.css('p').size != 3)
    first_column.children.css('p')[1].text.strip
  end

  def update_and_store(lawyers)
    stored_attorneys_md5 = collect_stored_md5
    unchanged_attorneys = []
    new_attorneys = []
    lawyers.each do |lawyer|
      next if lawyer[:md5_hash].nil?
      if stored_attorneys_md5.include?(lawyer[:md5_hash])
        unchanged_attorneys.push(lawyer[:md5_hash])
      else
        new_attorneys.push(lawyer)
      end
    end
    store_all(new_attorneys)
    update_touched_run_id(unchanged_attorneys)
    update_delete_status
  end

  def collect_stored_md5
    NMLawyerStatus.where(deleted: 0).pluck(:md5_hash).to_set
  end

  def store_all(attorneys)
    add_run_id(attorneys)
    attorneys.each_slice(CHUNK) do |attorneys_chunk|
      NMLawyerStatus.insert_all(attorneys_chunk)
    end
  end

  def update_touched_run_id(unchanged_attorney)
    unchanged_attorney.each_slice(CHUNK) do |unchanged_attorney_chunk|
      NMLawyerStatus.where(md5_hash: unchanged_attorney_chunk).update_all(touched_run_id: @run_id)
    end
  end

  def update_delete_status
    NMLawyerStatus.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def add_run_id(records)
    records.each do |rec|
      rec[:run_id] = @run_id
      rec[:touched_run_id] = @run_id
    end
  end

  def calc_md5_hash(hash)
    Digest::MD5.hexdigest hash.values.join
  end

  def log_store_started
    last_run = NMLawyerStatusRuns.last
    if last_run&.status == 'download finished'
      @run_id = last_run.id
      last_run.update(status: 'store started')
      puts "#{"="*50} store started #{"="*50}"
    else
      raise "Scrape work is not finished correctly"
    end
  end

  def log_store_finished
    last_run = NMLawyerStatusRuns.last
    NMLawyerStatusRuns.find(last_run.id).update(status: 'store finished')
    puts "#{"="*50} store finished #{"="*50}"
  end

end
