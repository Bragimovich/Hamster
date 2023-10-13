# frozen_string_literal: true
require_relative 'scraper'
require_relative 'manager'
require_relative 'keeper'

class Parser < Hamster::Parser
  def initialize
    super
    Hashie.logger = Logger.new(nil)
    @keeper = Keeper.new
  end

  def parse_csv_expenses(filename)
    data_hash = []
    CSV.foreach(filename, headers: true, col_sep: "\t", liberal_parsing: true, encoding:'iso-8859-1:utf-8', force_quotes: true, quote_char: "\x00") do |row|
      hash = row.to_h
      hash = hash.slice('doc_seq_no', 'expenditure_type', 'gub_expenditure_type', 'gub_elec_type', 'page_no', 'doc_type_desc', 'expense_id', 'detail_id', 'doc_stmnt_year', 'com_legal_name', 'cfr_com_id', 'com_type', 'schedule_desc', 'exp_desc', 'purpose', 'extra_desc', 'common_name', 'f_name', 'lname_or_org', 'address', 'city', 'state', 'zip', 'exp_date', 'amount', 'state_loc', 'supp_opp', 'can_or_ballot', 'county', 'debt_payment', 'vend_name', 'vend_city', 'vend_state', 'vend_zip', 'gotv_ink_ind', 'fundraiser')
      hash[:exp_date] = Date.strptime(hash['exp_date'], "%m/%d/%Y").to_s rescue nil
      hash[:data_source_url] = "https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/"
      generate_md5_hash(%i[doc_seq_no expenditure_type gub_expenditure_type gub_elec_type page_no doc_type_desc expense_id detail_id doc_stmnt_year com_legal_name cfr_com_id com_type schedule_desc exp_desc purpose extra_desc common_name f_name lname_or_org address city state zip exp_date amount state_loc supp_opp can_or_ballot county debt_payment vend_name vend_city vend_state vend_zip gotv_ink_ind fundraiser], hash)
      new_hash = hash.each do |k,v|
        hash[k] = v.squish unless v.nil?
        hash[k] = nil if v.blank? 
      end
      data_hash << new_hash
    end
    data_hash
  end


  def parse_csv_committees(filename)
    data_hash = []
    CSV.foreach(filename, headers: true, col_sep: "\t", encoding:'iso-8859-1:utf-8', quote_char: "\x00") do |row|
      hash = {}
      hash[:bureau_committee_id] = row['"Bureau Committee ID# (MaxLen=6)"']
      hash[:committee_type] = row['"Committee Type  (MaxLen=20)"'].gsub('"', '') rescue nil
      hash[:committee_group] = row['"Committee Group  (MaxLen=3)"']
      hash[:committee_status] = row['"Committee Status (MaxLen=3)"']
      hash[:committee_name] = row['"Committee Name (MaxLen=72)"'].gsub('"', '') rescue nil
      hash[:mailing_address] = row['"Mailing Address (MaxLen=62)"'].gsub('"', '') rescue nil
      hash[:mailing_city] = row['"Mailing City (MaxLen=20)"'].gsub('"', '') rescue nil
      hash[:mailing_state] = row['"Mailing State (MaxLen=2)"']
      hash[:mailing_zipcode] = row['"Mailing Zipcode (MaxLen=10)"']
      hash[:phone] = row['"Phone# (MaxLen=10)"']
      hash[:office_sought] = row['"Office Sought (MaxLen=80)"'].gsub('"', '') rescue nil
      hash[:district_sought] = row['"District Sought (MaxLen=80)"'].gsub('"', '') rescue nil
      hash[:political_party] = row['"Political Party (MaxLen=48)"'].gsub('"', '') rescue nil
      hash[:sofo_received_date] = Date.strptime(row['"SofO Received Date (MaxLen=10)"'], '%m/%d/%Y').to_s rescue nil
      hash[:committee_formed_date] = Date.strptime(row['"Committee Formed Date (MaxLen=10)"'], '%m/%d/%Y').to_s rescue nil
      hash[:data_source_url] = "https://cfrsearch.nictusa.com/"
      generate_md5_hash(%i[bureau_committee_id committee_type committee_group committee_status committee_name mailing_address mailing_city mailing_state mailing_zipcode phone office_sought district_sought political_party sofo_received_date committee_formed_date], hash)
      new_hash = hash.each do |k,v|
        hash[k] = v.squish unless v.nil?
        hash[k] = nil if v.blank?
        hash.delete(nil)
      end
      if hash[:bureau_committee_id].to_i == 0
        next 
      end
      data_hash << new_hash unless new_hash[:mailing_state] == "Address Search Results"
    end
    data_hash
  end

  def parse_csv_receipts(filename)
    data_hash = []
    CSV.foreach(filename, headers: true, col_sep: "\t", encoding:'iso-8859-1:utf-8', quote_char: "\x00") do |row|
      hash = row.to_h.symbolize_keys
      new_hash = {}
      new_hash = hash.slice(:doc_seq_no, :ik_code, :gub_account_type, :gub_elec_type, :page_no, :receipt_id, :detail_id, :doc_stmnt_year, :doc_type_desc, :com_legal_name, :common_name, :cfr_com_id, :com_type, :can_first_name, :can_last_name, :contribtype, :f_name, :l_name_or_org, :address, :city, :state, :zip, :occupation, :employer, :received_date, :amount, :aggregate, :extra_desc, :receipttype)
      new_hash = new_hash.each do |k,v|
        new_hash[k] = v.squish unless v.nil?
        new_hash[k] = nil if v.blank?
        new_hash.delete(nil)
      end
      new_hash[:received_date] = Date.strptime(new_hash[:received_date], "%m/%d/%Y").to_s rescue nil
      new_hash[:data_source_url] = "https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/"
      generate_md5_hash(%i[doc_seq_no ik_code gub_account_type gub_elec_type page_no receipt_id detail_id doc_stmnt_year doc_type_desc com_legal_name common_name cfr_com_id com_type can_first_name can_last_nam econtribtype f_name l_name_or_org address city state zip occupation employer received_date amount aggregate extra_desc], new_hash)
      data_hash << new_hash
    end
    data_hash
  end

  def parse_csv_contributions(filename)
    headers = ['doc_seq_no','page_no','contribution_id','cont_detail_id','doc_stmnt_year','doc_type_desc','com_legal_name','common_name','cfr_com_id','com_type','can_first_name','can_last_name','contribtype','f_name','l_name_or_org','address','city','state','zip','occupation','employer','received_date','amount','aggregate','extra_desc']
    first_line = File.foreach(filename).first
    unless first_line.include?('doc_seq_no')
      add_headers(filename, headers)
    end

    data_hash = []
    CSV.foreach(filename, encoding:'iso-8859-1:utf-8', headers: true, liberal_parsing: true, col_sep: "\t") do |row|
      hash = row.to_h
      new_hash = {}
      new_hash = hash.slice('doc_seq_no', 'page_no', 'contribution_id', 'cont_detail_id', 'doc_stmnt_year', 'doc_type_desc', 'com_legal_name', 'common_name', 'cfr_com_id', 'com_type', 'can_first_name', 'can_last_name', 'contribtype', 'f_name', 'l_name_or_org', 'address', 'city', 'state', 'zip', 'occupation', 'employer', 'received_date', 'amount', 'aggregate', 'extra_desc')
      new_hash = new_hash.each do |k,v|
        new_hash[k] = v.squish unless v.nil?
        new_hash[k] = nil if v.blank?
        new_hash.delete(nil)
      end
      new_hash['received_date'] = Date.strptime(new_hash['received_date'], "%m/%d/%Y").to_s rescue nil
      new_hash[:data_source_url] = "https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/"
      generate_md5_hash(%i[doc_seq_no page_no contribution_id cont_detail_id doc_stmnt_year doc_type_desc com_legal_name common_name cfr_com_id com_type can_first_name can_last_name contribtype f_name l_name_or_org address city state zip occupation employer received_date amount aggregate extra_desc], new_hash)
      data_hash << new_hash
    end
    data_hash
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end

  def add_headers(csv_file, headers)
    CSV.open(csv_file + '.tmp', 'w', write_headers: true, headers: headers, col_sep: "\t", liberal_parsing: true, encoding:'iso-8859-1:utf-8') do |dest|
      CSV.open(csv_file, encoding:'iso-8859-1:utf-8', liberal_parsing: true, col_sep: "\t") do |source|
        source.each do |row|
          dest << row
        end
      end
    end
  File.rename(csv_file + '.tmp', csv_file)
  end

  def unzip_file(file, destination)
    Zip::File.open(file) do |zip_file|
      zip_file.each do |f|
        f_path = File.join(destination, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end
    File.delete(file) if File.exist?(file)
  end

  def split_file(filename)
    file = filename.gsub('zip', 'txt')
    system("split -b 40m #{file} #{file}split")
    File.delete(file) if File.exist?(file)
  end
end
