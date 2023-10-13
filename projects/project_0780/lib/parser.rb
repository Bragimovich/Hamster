# frozen_string_literal: true

class Parser < Hamster::Parser

  def initialize(**params)
    super
    @keeper = Keeper.new
  end

  def parse_data(file, data_source_url, run_id, key)
    data_array = []
    md5_array = []
    CSV.foreach(file, headers: true, encoding: 'ISO-8859-1') do |row|
      data_hash = row.to_hash.reject{|e| e.nil?}.transform_keys{ |key| key.downcase.gsub(' ', '_') }
      data_hash = mark_empty_as_nil(data_hash)
      md5_hash  = create_md5_hash(data_hash)
      data_hash = data_hash.merge('md5_hash' => md5_hash)
      data_hash = data_hash.merge('run_id' => run_id)
      data_hash = data_hash.merge('touched_run_id' => run_id)
      data_hash = data_hash.merge('data_source_url' => data_source_url)
      data_hash = {} if ((data_hash['election'].nil?) && (data_hash.key?("election")))
      data_array << data_hash
      md5_array << md5_hash
      if (data_array.count == 5000)
        data_array = data_array.reject{ |e| e.empty? }
        md5_array = md5_array.reject{ |e| e.empty? }
        keeper.insert_records(data_array, key)
        keeper.update_touched_run_id(md5_array, key)
        data_array = []
        md5_array = []
      end
    end
    data_array = data_array.reject{ |e| e.empty? }
    md5_array = md5_array.reject{ |e| e.empty? }
    keeper.insert_records(data_array, key) unless data_array.empty?
    keeper.update_touched_run_id(md5_array, key) unless md5_array.empty?
  end

  def parse_report_data(file, data_source_url, run_id, key)
    data_array = []
    md5_array = []
    CSV.foreach(file, encoding: 'ISO-8859-1', liberal_parsing: true) do |row|
      data_hash = {}
      data_hash['filer_id']               = get_row_value(row, 0)
      data_hash['filer_previous_id']      = get_row_value(row, 1)
      data_hash['cand_comm_name']         = get_row_value(row, 2)
      data_hash['election_year']          = get_row_value(row, 3)
      data_hash['election_type']          = get_row_value(row, 4)
      data_hash['county_desc']            = get_row_value(row, 5)
      data_hash['filing_abbrev']          = get_row_value(row, 6)
      data_hash['filing_desc']            = get_row_value(row, 7)
      data_hash['r_amend']                = get_row_value(row, 8)
      data_hash['filing_cat_desc']        = get_row_value(row, 9)
      data_hash['filing_sched_abbrev']    = get_row_value(row, 10)
      data_hash['filing_sched_desc']      = get_row_value(row, 11)
      data_hash['loan_lib_number']        = get_row_value(row, 12)
      data_hash['trans_number']           = get_row_value(row, 13)
      data_hash['trans_mapping']          = get_row_value(row, 14)
      data_hash['sched_date']             = get_row_value(row, 15)
      data_hash['org_date']               = get_row_value(row, 16)
      data_hash['cntrbr_type_desc']       = get_row_value(row, 17)
      data_hash['cntrbn_type_desc']       = get_row_value(row, 18)
      data_hash['transfer_type_desc']     = get_row_value(row, 19)
      data_hash['receipt_type_desc']      = get_row_value(row, 20)
      data_hash['receipt_code_desc']      = get_row_value(row, 21)
      data_hash['purpose_code_desc']      = get_row_value(row, 22)
      data_hash['r_subcontractor']        = get_row_value(row, 23)
      data_hash['flng_ent_name']          = get_row_value(row, 24)
      data_hash['flng_ent_first_name']    = get_row_value(row, 25)
      data_hash['flng_ent_middle_name']   = get_row_value(row, 26)
      data_hash['flng_ent_last_name']     = get_row_value(row, 27)
      data_hash['flng_ent_add1']          = get_row_value(row, 28)
      data_hash['flng_ent_city']          = get_row_value(row, 29)
      data_hash['flng_ent_state']         = get_row_value(row, 30)
      data_hash['flng_ent_zip']           = get_row_value(row, 31)
      data_hash['flng_ent_country']       = get_row_value(row, 32)
      data_hash['payment_type_desc']      = get_row_value(row, 33)
      data_hash['pay_number']             = get_row_value(row, 34)
      data_hash['owed_amt']               = get_row_value(row, 35)
      data_hash['org_amt']                = get_row_value(row, 36)
      data_hash['loan_other_desc']        = get_row_value(row, 37)
      data_hash['trans_explntn']          = get_row_value(row, 38)
      data_hash['r_itemized']             = get_row_value(row, 39)
      data_hash['r_liability']            = get_row_value(row, 40)
      data_hash['election_year_r']        = get_row_value(row, 41)
      data_hash['office_desc']            = get_row_value(row, 42)
      data_hash['district']               = get_row_value(row, 43)
      data_hash['dist_off_cand_bal_prop'] = get_row_value(row, 44)
      data_hash                           = mark_empty_as_nil(data_hash)
      data_hash['md5_hash']               = create_md5_hash(data_hash)
      data_hash['run_id']                 = run_id
      data_hash['touched_run_id']         = run_id
      data_hash['data_source_url']        = data_source_url
      data_array << data_hash
      md5_array << data_hash['md5_hash']
      if (data_array.count == 5000)
        data_array = data_array.reject{ |e| e.empty? }
        md5_array = md5_array.reject{ |e| e.empty? }
        keeper.insert_records(data_array, key)
        keeper.update_touched_run_id(md5_array, key)
        data_array = []
        md5_array = []
      end
    end
    data_array = data_array.reject{ |e| e.empty? }
    md5_array = md5_array.reject{ |e| e.empty? }
    keeper.insert_records(data_array, key) unless data_array.empty?
    keeper.update_touched_run_id(md5_array, key) unless md5_array.empty?
  end

  def parse_filer_data(file, data_source_url, run_id, key)
    data_array = []
    md5_array = []
    rows = CSV.foreach(file, encoding: 'ISO-8859-1')
    headers = rows.select{|e| e.join.downcase.include? 'filer'}.first.map{|e| e.to_s.downcase.squish}
    rows.each_with_index do |row,index|
      next if (index == 0)
      data_hash = {}
      data_hash[:filer_type]        = get_value(row, headers, 'filer type')
      data_hash[:compliance_type]   = get_value(row, headers, 'compliance')
      data_hash[:committee_type]    = get_value(row, headers, 'committee')
      data_hash[:filer_id]          = get_value(row, headers, 'filer id')
      data_hash[:name]              = get_value(row, headers, 'name')
      data_hash[:office]            = get_value(row, headers, 'office')
      data_hash[:district]          = get_value(row, headers, 'district')
      data_hash[:county]            = get_value(row, headers, 'county')
      data_hash[:municipality]      = get_value(row, headers, 'municipality')
      data_hash[:address]           = get_value(row, headers, 'address')
      data_hash[:registration_date] = get_value(row, headers, 'registration date')
      data_hash[:termination_date]  = get_value(row, headers, 'termination date')
      data_hash[:status]            = get_value(row, headers, 'status')
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      data_hash[:run_id]            = run_id
      data_hash[:touched_run_id]    = run_id
      data_hash[:data_source_url]   = data_source_url
      data_hash                     = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
      if (data_array.count == 5000)
        data_array = data_array.reject{ |e| e.empty? }
        md5_array = md5_array.reject{ |e| e.empty? }
        keeper.insert_records(data_array, key)
        keeper.update_touched_run_id(md5_array, key)
        data_array = []
        md5_array = []
      end
    end
    data_array = data_array.reject{ |e| e.empty? }
    md5_array = md5_array.reject{ |e| e.empty? }
    keeper.insert_records(data_array, key) unless data_array.empty?
    keeper.update_touched_run_id(md5_array, key) unless md5_array.empty?
  end

  def parse_candidate_data(page_body)
    data_array = []
    md5_array = []
    page = parse_html_page(page_body)
    table_rows = page.css('table#CandidateGrid tbody tr')
    table_rows.each do |table_row|
      data_rows = table_row.css('td')
      return [[{}],[]] if (data_rows.text.include? 'No data available in table')
      data_hash = {}
      data_hash[:committee_filer_id] = page.text.split('=>').last.to_s.squish
      data_hash[:filer_type]         = get_td_value(data_rows, 1)
      data_hash[:filer_id]           = get_td_value(data_rows, 2)
      data_hash[:candidate_name]     = get_td_value(data_rows, 3)
      data_hash[:year]               = get_td_value(data_rows, 4)
      data_hash[:office]             = get_td_value(data_rows, 5)
      data_hash[:district]           = get_td_value(data_rows, 6)
      data_hash[:county]             = get_td_value(data_rows, 7)
      data_hash[:municipality]       = get_td_value(data_rows, 8)
      data_hash[:address]            = get_td_value(data_rows, 9)
      data_hash[:registration_date]  = get_td_value(data_rows, 10)
      data_hash[:termination_date]   = get_td_value(data_rows, 11)
      data_hash[:md5_hash]           = create_md5_hash(data_hash)
      data_hash[:run_id]             = keeper.run_id
      data_hash[:touched_run_id]     = keeper.run_id
      data_hash[:data_source_url]    = 'https://publicreporting.elections.ny.gov/ActiveDeactiveFiler/ActiveDeactiveFiler'
      data_hash                      = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  private

  attr_reader :keeper

  def get_td_value(data_rows, index)
    data_rows[index].text.to_s.squish
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def get_row_value(row, index)
    row[index].squish rescue nil
  end

  def get_value(row,headers,key)
    value_index = headers.index(headers.select{ |e| e.include? key }.first)
    row[value_index].to_s.squish unless value_index.nil?
  end

  def parse_html_page(page_body)
    Nokogiri::HTML(page_body.force_encoding('utf-8'))
  end

end
