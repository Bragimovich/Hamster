# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  PATH = "/home/hamster/HarvestStorehouse/project_0324/store"

  def initialize
    super

    @scraper = Scraper.new
    @keeper  = Keeper.new
  end

  def download_csv_file

    resp = @scraper.csv_download_get_request
    raise 'METHOD csv_page_get_request RETURN NIL' if resp[:resp].nil?
    raise 'ERROR DURING DOWNLOADING CSV' unless resp[:resp].success?

    # for testing uncomment
    # resp = {}
    # resp[:file_path] = '/Users/abdulwahab/HarvestStorehouse/project_0324/store/connecticut_prof_license_20230409T003127642.csv'

    prepared_file = @scraper.prepare_csv_to_upload(resp[:file_path])
    Hamster.logger.debug 'UPDATED FILE SAVED'

    trash_file_path = @scraper.move_file_to_trash(resp[:file_path])
    Hamster.logger.debug 'FILE MOVED TO TRASH' if trash_file_path

    tar_file_path = @scraper.file_to_tar(trash_file_path)
    Hamster.logger.debug 'FILE PUT IN TAR' if tar_file_path
  rescue StandardError => e
    Hamster.logger.debug e
    Hamster.logger.debug e.backtrace
  end

  def store_csv_file

    prepared_file = "#{PATH}/connecticut_prof_license_#{Time.now.strftime('%Y%m%d')}_prepared.csv"
    file_path = "#{PATH}/connecticut_prof_license_#{Time.now.strftime('%Y%m%d')}.csv"

    Hamster.logger.debug 'CSV DATA UPLOADED'          if @keeper.upload_csv_data(prepared_file)
    Hamster.logger.debug 'GENERATED MD5 ON TMP TABLE' if @keeper.generate_md5_on_tmp_table
    Hamster.logger.debug 'MARK DELETED RECORDS'       if @keeper.mark_deleted_records
    Hamster.logger.debug 'DELETE RECORDS FROM TMP WHICH ARE AVAILABLE IN MAIN' if @keeper.update_tmp_table
    Hamster.logger.debug 'COPY NEW LICENSES'          if @keeper.copy_new_licenses



    trash_file_path = @scraper.move_file_to_trash(prepared_file)
    Hamster.logger.debug 'FILE MOVED TO TRASH' if trash_file_path

    tar_file_path = @scraper.file_to_tar(trash_file_path)
    Hamster.logger.debug 'FILE PUT IN TAR' if tar_file_path

    @keeper.set_run_id

  rescue StandardError => e
    Hamster.logger.debug e
    Hamster.logger.debug e.backtrace
  end
end
