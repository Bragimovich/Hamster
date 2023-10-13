class CsvParser < Hamster::Parser
  def initialize
    super
  end

  def parse_receipt_data(file_path)
    receipt_data = []
    begin
      CSV.foreach(file_path, headers: true) do |row|
        data = {}
        data[:transaction_date] = Date.strptime(row[0], '%m/%d/%Y') rescue nil
        data[:filing_period_name] = row[1]
        data[:contributor_name] = row[2]
        data[:contribution_amount] = row[3]
        data[:address_line1] = row[4]
        data[:address_line2] = row[5]
        data[:city] = row[6]
        data[:state] = row[7]
        data[:zip] = row[8]
        data[:occupation_title] = row[9]
        data[:employer_name] = row[10]
        data[:employer_address] = row[11]
        data[:contributor_type] = row[12]
        data[:receiving_committee_name] = row[13]
        data[:committee_id] = row[14]
        data[:conduit] = row[15]
        data[:office_branch] = row[16]
        data[:comment] = row[17][0..500] rescue nil
        data[:hr_reports] = row[18]
        data[:segregated_fund_flag] = row[19].downcase == 'false' ? false : true
        data[:data_source_url] = 'https://cfis.wi.gov/Public/Registration.aspx?page=ReceiptList'
        data[:md5_hash] = create_md5_hash(data)
        receipt_data << data
      end
    rescue => e
      logger.info e.full_message
    end
    receipt_data
  end

  def parse_expense_data(file_path)
    expense_data = []
    begin
      CSV.foreach(file_path, headers: true) do |row|
        data = {}
        data[:registrant_name] = row[0]
        data[:committee_id] = row[1]
        data[:office_branch] = row[2]
        data[:payee_name] = row[3]
        data[:transaction_date] = Date.strptime(row[4], '%m/%d/%Y') rescue nil
        data[:communication_date] = Date.strptime(row[5], '%m/%d/%Y') rescue nil
        data[:expense_purpose] = row[6]
        data[:expense_category] = row[7]
        data[:filing_period_name] = row[8]
        data[:filing_fee_name] = row[9]
        data[:recount_name] = row[10]
        data[:recall_name] = row[11]
        data[:referendum_name] = row[12]
        data[:ind_exp_candidate_name] = row[13]
        data[:support_oppose] = row[14]
        data[:amount] = row[15]
        data[:comment] = row[16][0..500] rescue nil
        data[:hr_reports] = row[17]
        data[:payee_address_line1] = row[18]
        data[:payee_address_line2] = row[19]
        data[:payee_city] = row[20]
        data[:payee_state] = row[21]
        data[:payee_zip] = row[22]
        data[:segregated_fund_flag] = row[23].downcase == 'false' ? false : true
        data[:data_source_url] = 'https://cfis.wi.gov/Public/Registration.aspx?page=ExpenseList'
        data[:md5_hash] = create_md5_hash(data)
        expense_data << data
      end
    rescue => e
      logger.info e.full_message
    end
    expense_data
  end
  
  private

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end

