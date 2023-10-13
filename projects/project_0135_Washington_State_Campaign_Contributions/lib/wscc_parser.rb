# frozen_string_literal: true

class Parser < Hamster::Parser

  FILENAME = "Contributions_to_Candidates_and_Political_Committees.csv"
  URL = "https://data.wa.gov/Politics/Contributions-to-Candidates-and-Political-Committe/kv7h-kjye"
  COLUMNS = [:contribution_id, :report_number, :origin, :committee_id, :filer_id, :type, :filer_name, :office, :legislative_district, :position, :party, :ballot_number, :for_or_against, :jurisdiction, :jurisdiction_county, :jurisdiction_type, :election_year, :amount, :cash_or_in_kind, :receipt_date, :description, :memo, :primary_general, :code, :contributor_category, :contributor_name, :contributor_address, :contributor_city, :contributor_state, :contributor_zip, :contributor_occupation, :contributor_employer_name, :contributor_employer_city, :contributor_employer_state, :url, :contributor_location]

  def initialize
    super
    run_id_class = WSCCRunId.new
    @run_id = run_id_class.run_id
    answer = file_to_temp_table
    return answer if answer == 1
    p @run_id
    mark_deleted_rows(@run_id)
    run_id_class.finish
    transfer_temp_to_general(@run_id)
  end

  def file_to_temp_table
    peon = Peon.new(storehouse)
    contributions = []
    skip_rows = 0
    skip_rows_filename = "#{storehouse}/skip_rows"
    headers = nil
    if "#{FILENAME}.gz".in? peon.give_list
      filename = peon.move_and_unzip_temp(file:FILENAME)
    else
      filename = storehouse + 'trash/' + FILENAME
      if File.exist? skip_rows_filename
        File.open(skip_rows_filename, 'r') { |file| skip_rows=file.read.to_i}
      end
    end
    return 1 unless File.exist?(filename)
    i = 0
    array_md5_hashes = []
    CSV.foreach(filename, headers: true, header_converters: :symbol) do |row|
      i += 1

      next if i<=skip_rows
      headers ||= row.headers
      contributions << row.to_h
      contributions[-1][:amount] = contributions[-1][:amount].to_f
      contributions[-1][:receipt_date] = Date.strptime(contributions[-1][:receipt_date], '%m/%d/%Y') unless contributions[-1][:receipt_date].nil?
      contributions[-1][:run_id] = @run_id
      contributions[-1][:touched_run_id] = @run_id
      contributions[-1][:contribution_id] = contributions[-1][:id]
      contributions[-1].delete(:id)

      md5_hash = generate_md5(contributions[-1])
      contributions[-1][:md5_hash] = md5_hash
      array_md5_hashes.push(md5_hash)
      if i%1000 == 0
        p i
        #put_in_table(contributions, array_md5_hashes)
        contributions = []
        array_md5_hashes = []
        File.open(skip_rows_filename, 'w') { |file| file.write(i.to_s) }
      end
    end
    #put_in_table(contributions, array_md5_hashes)
    File.open(skip_rows_filename, 'w') { |file| file.write('0') }
    peon.throw_temps()
  end


  def put_in_table(contributions, array_md5_hashes)
    existed_md5_hash = existing_md5_hash(array_md5_hashes, @run_id)
    new_contributions_row = []
    contributions.each do |contribution|
      next if contribution[:md5_hash].in? existed_md5_hash
      new_contributions_row.push(contribution)
    end

    insert_all(new_contributions_row) unless new_contributions_row.empty?
  end

  def generate_md5(data)
    all_values_str = ''
    COLUMNS.each do |key|
      if data[key].nil?
        all_values_str = all_values_str + data[key.to_s].to_s
      else
        all_values_str = all_values_str + data[key].to_s
      end
    end
    Digest::MD5.hexdigest all_values_str
  end

end


class ParserNew < Hamster::Scraper

  def initialize(type=nil)
    super
    run_id_class = WSCCRunId.new
    @run_id = run_id_class.run_id
    @peon = Peon.new(storehouse)
    if type.nil?
      parse_all_files
    elsif [:contribute, :expenditures, :candidate].include?(type.to_sym)
      parse_file(type.to_sym)
    else
      log("Not this type: #{type}")
    end
    run_id_class.finish
    @peon.throw_temps()
    1
  end

  def parse_all_files
    [:candidate, :expenditures, :contribute].each do |type| #,
      parse_file(type)
    end
  end

  def parse_file(type)
    log("Parsing #{type}...", color='yellow')
    file_to_temp_table(type)
    mark_deleted_rows_new(@run_id, type)
  end


  def file_to_temp_table(type=:expenditures)
    #contributions = []
    skip_rows = 0
    skip_rows_filename = "#{storehouse}/skip_rows_#{type}"
    headers = nil
    if "#{filename_csv[type]}.gz".in? @peon.give_list
      filename = @peon.move_and_unzip_temp(file:filename_csv[type])
    else
      filename = storehouse + 'trash/' + filename_csv[type]
      if File.exist? skip_rows_filename
        File.open(skip_rows_filename, 'r') { |file| skip_rows=file.read.to_i}
      end
    end
    return 1 unless File.exist?(filename)
    i = 0
    array_md5_hashes = []
    q=0
    w=0
    CSV.foreach(filename, headers: true, header_converters: :symbol) do |row|
      i += 1
      next if i<=skip_rows
      headers ||= row.headers
      contributions = row.to_h

      contributions[:amount] = contributions[:amount].to_f unless contributions[:amount].nil?

      unless contributions[:receipt_date].nil?
        if type==:candidate
          contributions[:receipt_date] = Date.parse(contributions[:receipt_date])
        else
          contributions[:receipt_date] = Date.strptime(contributions[:receipt_date], '%m/%d/%Y')
        end
      end

      contributions[:expenditure_date] = Date.strptime(contributions[:expenditure_date], '%m/%d/%Y') unless contributions[:expenditure_date].nil?
      contributions[:election_date] = Date.strptime(contributions[:election_date], '%m/%d/%Y') unless contributions[:election_date].nil?


      contributions[:touched_run_id] = @run_id
      if type!=:candidate
        contributions[:contribution_id] = contributions[:id]
      else
        contributions[:id_csv] = contributions[:id]
      end
      contributions.delete(:id)
      md5_hash = generate_md5(contributions, type)
      contributions[:md5_hash] = md5_hash
      #array_md5_hashes.push(md5_hash)

      contr_in_db = existed_row_by_md5(md5_hash,type)
      contributions[:deleted] = 0
      if contr_in_db.first.nil?
        contributions[:run_id] = @run_id
        wscc_insert(contributions, type)
        w+=1
      else
        q+=1
        wscc_update(contr_in_db, @run_id)
      end


      if i%1000 == 0
        p i
        #put_in_table(contributions, array_md5_hashes, type)
        #contributions = []
        #array_md5_hashes = []
        File.open(skip_rows_filename, 'w') { |file| file.write(i.to_s) }
        reconnect_db(type)
      end
    end
    p "Update: #{q}. Insert: #{w}"
    #put_in_table(contributions, array_md5_hashes, type)
    File.open(skip_rows_filename, 'w') { |file| file.write('0') }

  end


  def put_in_table(contributions, array_md5_hashes, type)
    existed_md5_hash = existing_md5_hash_new(array_md5_hashes, @run_id, type)
    new_contributions_row = []
    contributions.each do |contribution|
      next if contribution[:md5_hash].in? existed_md5_hash
      new_contributions_row.push(contribution)
    end

    insert_all_new(new_contributions_row, type ) unless new_contributions_row.empty?
  end

  def generate_md5(data, type=:contribute)
    all_values_str = ''
    columns_table[type].each do |key|
      if data[key].nil?
        all_values_str = all_values_str + data[key.to_s].to_s
      else
        all_values_str = all_values_str + data[key].to_s
      end
    end
    Digest::MD5.hexdigest all_values_str
  end

  private

  def filename_csv
    {
      :contribute => "Contributions_to_Candidates_and_Political_Committees.csv",
      :expenditures => "Expenditures_by_Candidates_and_Political_Committees.csv",
      :candidate => "Candidate_and_Committee_Registrations.csv",
    }
  end

  def url
    {
      :contribute => "https://data.wa.gov/api/views/kv7h-kjye/rows.csv?accessType=DOWNLOAD",
      :expenditures => "https://data.wa.gov/api/views/tijg-9zyp/rows.csv?accessType=DOWNLOAD",
      :candidate => "https://data.wa.gov/api/views/iz23-7xxj/rows.csv?accessType=DOWNLOAD"
    }
  end

  def columns_table
    {
      :contribute => [:contribution_id, :report_number, :origin, :committee_id, :filer_id, :type, :filer_name, :office, :legislative_district, :position, :party, :ballot_number, :for_or_against, :jurisdiction, :jurisdiction_county, :jurisdiction_type, :election_year, :amount,
                      :cash_or_in_kind, :receipt_date, :description, :memo, :primary_general, :code, :contributor_category, :contributor_name, :contributor_address, :contributor_city, :contributor_state, :contributor_zip, :contributor_occupation, :contributor_employer_name,
                      :contributor_employer_city, :contributor_employer_state, :url, :contributor_location],
      :expenditures => [:report_number, :origin, :committee_id, :filer_id, :type, :filer_name, :office, :legislative_district, :position, :party, :ballot_number, :for_or_against, :jurisdiction, :jurisdiction_county, :jurisdiction_type, :election_year, :amount, :itemized_or_non_itemized, :expenditure_date,
                        :description,:code, :recipient_name, :recipient_address, :recipient_city, :recipient_state, :recipient_zip, :url, :recipient_location, :contribution_id],
      :candidate => [:id_csv, :committee_id, :candidate_id, :filer_id, :filer_type, :filer_name, :receipt_date, :election_year, :committee_acronym, :committee_address, :committee_city, :committee_county, :committee_state, :committee_zip, :committee_email, :candidate_email, :office, :office_code,
                     :jurisdiction, :jurisdiction_code, :jurisdiction_county, :jurisdiction_type, :committee_category, :political_committee_type, :bonafide_committee, :bonafide_type, :position, :party_code, :party, :election_date, :exempt_nonexempt, :ballot_committee, :ballot_number,
                     :for_or_against, :other_pac, :treasurer_name, :treasurer_address, :treasurer_city, :treasurer_state, :treasurer_zip, :treasurer_phone, :url
      ],
    }
  end

end


