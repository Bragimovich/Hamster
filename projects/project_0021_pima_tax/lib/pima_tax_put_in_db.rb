
class PutInDb < Hamster::Scraper

  def initialize
    @run_id = get_run_id
  end

  def exist(md5_array)
    existed_md5 = []
    PimaTaxpayers.where(md5_hash: md5_array).each { |line| existed_md5.push(line.md5_hash) }
    existed_md5
  end

  def reconnect
    PimaTaxpayers.connection.reconnect!
  end

  def update_touched_run_id(existed_md5)
    taxpayers = PimaTaxpayers.where(md5_hash: existed_md5)
    taxpayers.update_all "touched_run_id=#{@run_id}, deleted = 0"
  end

  def update_delete_status
    taxpayers = PimaTaxpayers.where.not(touched_run_id:@run_id)
    taxpayers.update_all "deleted = 1"
  end

  def save(taxpayers_data, existed_md5)
    taxpayers_data.each do |line|
      if line['md5_hash'].in? existed_md5
        pima_taxpayer = PimaTaxpayers.where(md5_hash:line['md5_hash']).first
        pima_taxpayer.taxpayer_state_code = line["state_code"]
        pima_taxpayer.property_url = "https://www.to.pima.gov/propertyInquiry/?stateCodeB=None&stateCodeM=None&stateCodeP=None&stateCodePP=#{line["state_code"]}"
        pima_taxpayer.save
        next
      end
      pima_taxpayer = PimaTaxpayers.new do |pima|
        pima.taxpayer_name = line["taxpayer_name"]
        pima.taxpayer_address = line["taxpayer_address"]
        pima.taxpayer_city_state_zip = line["taxpayer_city_state_zip"]
        pima.property_address = line["property_addresss"]
        pima.property_type = line["property_type"]
        pima.tax_year = line["tax_year"]
        pima.interest_date = line["interest_date"]
        pima.interest_pct = line["interest_percent"]
        pima.amount = line["amount"]
        pima.interest = line["interest"]
        pima.fees = line["fees"]
        pima.penalties = line["penalties"]
        pima.total_due = line["total_due"]
        pima.taxpayer_state_code = line["state_code"]
        pima.property_url = "https://www.to.pima.gov/propertyInquiry/?stateCodeB=None&stateCodeM=None&stateCodeP=None&stateCodePP=#{line["state_code"]}"
        pima.scrape_frequency = 'monthly'
        pima.data_source_url = 'https://www.to.pima.gov/propertySearch/'
        pima.md5_hash = line['md5_hash']
        pima.run_id = @run_id
        pima.touched_run_id = @run_id
      end
      pima_taxpayer.save
      existed_md5.push(line['md5_hash'])
    end
  end


  def get_run_id
    PimaTaxpayersRuns.find_or_create_by(status:'processing').id
  end

  def put_done_for_run_id
    runs = PimaTaxpayersRuns.find_by(id:@run_id)
    runs.status = 'done'
    runs.save
  end

end