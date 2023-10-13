require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper    = Keeper.new
    @parser    = Parser.new
    @scraper   = Scraper.new
    @subfolder = "Run_Id_#{@keeper.run_id}"
    @downloaded_files = peon.give_list(subfolder: @subfolder)
    @s3 = AwsS3.new(bucket_key = :hamster, account = :hamster)
  end

  def run
    (keeper.download_status(keeper.run_id)[0].to_s == "true") ? store : download
  end

  private

  def update_old_records
    ids = keeper.fetch_ids
    array = []
    ids.each do |id|
      agree_token = scraper.agree_request_token
      token = scraper.get_token(agree_token)
      page = scraper.main_page(id, token)
      if page.status == 500
        array << id
      else
        save_file(page.body, id.to_s)
      end
    end
    keeper.update_status(array)
  end

  def download
    update_old_records
    start_date = (keeper.already_inserted_date.max + 1).to_s
    current_date = Date.today
    start_date.to_date.upto(current_date).to_a.reverse.each do |date|
      generate_booking_number(date.to_s.gsub("-",""))
    end
    keeper.mark_download_status(keeper.run_id)
    store if (keeper.download_status(keeper.run_id)[0].to_s == "true")
  end

  def store
    already_inserted_records = keeper.already_inserted_on_same_run_id
    @downloaded_files.each do |file_name|
      next if already_inserted_records.include? "#{file_name}.gz"
      run_id = keeper.run_id
      data_hash_facility, data_arrestes, data_hash_aws = {}
      file = peon.give(subfolder:@subfolder, file:file_name)
      data = parser.parse(file, run_id)
      arrestees_id = keeper.save_record(data, "IlCookArrestees")
      data_arrestes = parser.parse_arrestes(file, arrestees_id, run_id)
      arrest_id = keeper.save_record(data_arrestes, "IlCookArrests")
      court_hearing(run_id, file, arrest_id)
      data_hash_facility = parser.parse_facility(file, arrest_id, run_id)
      data_hash_aws = parser.parse_image(file, arrestees_id, data_arrestes[:booking_number], run_id)
      data_hash_aws[:aws_link] = upload_file_to_aws(data_hash_aws)
      keeper.common_insertion(data_hash_facility, data_hash_aws)
    end
    keeper.finish
  end

  attr_reader :keeper, :parser, :scraper

  def upload_file_to_aws(aws_record)
    aws_url = "https://hamster-storage1.s3.amazonaws.com/"
    return aws_url + aws_record[:aws_link] unless @s3.find_files_in_s3(aws_record[:aws_link]).empty?
    key = aws_record[:aws_link]
    image_url = aws_record[:original_link]
    response, code = scraper.connect_to(image_url)
    return nil if code == 500
    content = response&.body
    @s3.put_file(content, key, metadata={})
  end

  def court_hearing(run_id, file, arrest_id)
    count = parser.court_count(file)
    (3...count-1).each do |i|
    data_hash = parser.parse_court(file, arrest_id, run_id, i)
    hearing_id = keeper.save_record(data_hash, "IlCookCourtHearings")
    bond_data_hash = parser.parse_bond(file, arrest_id, run_id, i, hearing_id)
    keeper.save_bond(bond_data_hash) unless bond_data_hash.nil?
    end
  end

  def save_file(response, file_name)
    peon.put content:response, file: file_name.to_s, subfolder:@subfolder
  end

  def generate_booking_number(date)
    booking_number = date + "001"

    empty_records_count = 0
    (0...1000).each do|i|
      agree_token = scraper.agree_request_token
      token = scraper.get_token(agree_token)
      id =  booking_number.to_i + i
      next if @downloaded_files.include? "#{id}.gz"
      break if empty_records_count > 50
      page = scraper.main_page(id, token)

      if page.status == 500
        empty_records_count+=1
        next
      end
      empty_records_count = 0
      save_file(page.body, id.to_s)
    end
  end
end
