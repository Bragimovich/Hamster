require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def scrape
    download
    store
  end

  def download(options=nil)
    type_list = options[:type].split(',') if options && options[:type]
    @scraper.scrape_zip_files(type_list)
  end

  def store(options=nil)
    if options && options[:type]
      type_list = options[:type].split(',')
    else
      @keeper.sync_general_info_table
      type_list = @scraper.zip_file_page_urls.map{|url| url.match(/value=(\w+)$/)[1]}
    end
    type_list.each do |download_type|
      file_path = @scraper.store_file_path(download_type)
      logger.debug("Storing #{download_type}, file_path: #{file_path}")
      case download_type
      when 'Enrollment'
        store_enrollment(file_path)
      when 'WSAS'
        store_wsas(file_path)
      when 'ACT11'
        store_act11(file_path)
      when 'ACT'
        store_act(file_path)
      when 'Aspire'
        store_aspire(file_path)
      when 'Forward'
        store_forward(file_path)
      when 'Discipline'
        store_discipline(file_path)
      when 'Attendance'
        store_attendance_and_dropout(file_path)
      end
    end
    @keeper.finish
  end

  def store_enrollment(file_path)
    get_file_list(file_path).each do |csv_file_path|
      logger.debug("Storing enrollment, csv_file_path: #{csv_file_path}")
      file_name = csv_file_path.match(/store\/\d{4}\/\w+\/(\w.*\.csv)/)[1]
      CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
        data_source = "#{file_name}##{ind}"
        hash_data = @parser.parse_enrollment_csv(row, data_source)
        general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
        hash_data[:general_id] = general_info.id
        @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiEnrollment')
      end
      delete_file(csv_file_path)
    end
    @keeper.flush('WiEnrollment')
  end

  def store_wsas(file_path)
    get_file_list(file_path).each do |csv_file_path|
      logger.debug("Storing wsas, csv_file_path: #{csv_file_path}")
      file_name = csv_file_path.match(/store\/\d{4}\/\w+\/(\w.*\.csv)/)[1]
      CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
        data_source = "#{file_name}##{ind}"
        hash_data = @parser.parse_wsas_csv(row, data_source)
        general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
        hash_data[:general_id] = general_info.id
        @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiAssessmentWsas')
      end
      delete_file(csv_file_path)
    end
    @keeper.flush('WiAssessmentWsas')
  end

  def store_act11(file_path)
    get_file_list(file_path).each do |csv_file_path|
      logger.debug("Storing act11, csv_file_path: #{csv_file_path}")
      file_name = csv_file_path.match(/store\/\d{4}\/\w+\/(\w.*\.csv)/)[1]
      CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
        data_source = "#{file_name}##{ind}"
        hash_data = @parser.parse_act11_csv(row, data_source)
        general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
        hash_data[:general_id] = general_info.id
        @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiAssessmentAct')
      end
      delete_file(csv_file_path)
    end
    @keeper.flush('WiAssessmentAct')
  end

  def store_act(file_path)
    get_file_list(file_path).each do |csv_file_path|
      logger.debug("Storing act, csv_file_path: #{csv_file_path}")
      file_name = csv_file_path.match(/store\/\d{4}\/\w+\/(\w.*\.csv)/)[1]
      CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
        data_source = "#{file_name}##{ind}"
        hash_data = @parser.parse_act_csv(row, data_source)
        general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
        hash_data[:general_id] = general_info.id
        @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiAssessmentActGrad')
      end
      delete_file(csv_file_path)
    end
    @keeper.flush('WiAssessmentActGrad')
  end

  def store_aspire(file_path)
    get_file_list(file_path).each do |csv_file_path|
      logger.debug("Storing aspire, csv_file_path: #{csv_file_path}")
      file_name = csv_file_path.match(/store\/\d{4}\/\w+\/(\w.*\.csv)/)[1]
      CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
        data_source = "#{file_name}##{ind}"
        hash_data = @parser.parse_aspire_csv(row, data_source)
        general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
        hash_data[:general_id] = general_info.id
        @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiAssessmentAspire')
      end
      delete_file(csv_file_path)
    end
    @keeper.flush('WiAssessmentAspire')
  end

  def store_forward(file_path)
    get_file_list(file_path).each do |csv_file_path|
      logger.debug("Storing forward, csv_file_path: #{csv_file_path}")
      file_name = csv_file_path.match(/store\/\d{4}\/\w+\/(\w.*\.csv)/)[1]
      CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
        data_source = "#{file_name}##{ind}"
        hash_data = @parser.parse_forward_csv(row, data_source)
        general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
        hash_data[:general_id] = general_info.id
        @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiAssessmentForward')
      end
      delete_file(csv_file_path)
    end
    @keeper.flush('WiAssessmentForward')
  end

  def store_discipline(file_path)
    get_file_list(file_path).each do |csv_file_path|
      file_name = csv_file_path.match(/store\/\d{4}\/\w+\/(\w.*\.csv)/)[1]
      if csv_file_path.match(/discipline_actions/)
        logger.debug("Storing discipline_actions, csv_file_path: #{csv_file_path}")
        store_discipline_actions(csv_file_path, file_name)
      elsif csv_file_path.match(/discipline_incidents/)
        logger.debug("Storing discipline_incidents, csv_file_path: #{csv_file_path}")
        store_discipline_incidents(csv_file_path, file_name)
      else
        delete_file(csv_file_path)
        next
      end
      delete_file(csv_file_path)
    end
  end
  def store_discipline_actions(csv_file_path, file_name)
    CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
      data_source = "#{file_name}##{ind}"
      hash_data = @parser.parse_discipline_actions_csv(row, data_source)
      general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
      hash_data[:general_id] = general_info.id
      @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiDisciplineAction')
    end
    @keeper.flush('WiDisciplineAction')
  end
  def store_discipline_incidents(csv_file_path, file_name)
    CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
      data_source = "#{file_name}##{ind}"
      hash_data = @parser.parse_discipline_incidents_csv(row, data_source)
      general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
      hash_data[:general_id] = general_info.id
      @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiDisciplineIncident')
    end
    @keeper.flush('WiDisciplineIncident')
  end

  def store_attendance_and_dropout(file_path)
    get_file_list(file_path).each do |csv_file_path|
      file_name = csv_file_path.match(/store\/\d{4}\/\w+\/(\w.*\.csv)/)[1]
      if csv_file_path.match(/attendance_certified/)
        logger.debug("Storing attendance_certified, csv_file_path: #{csv_file_path}")
        store_attendance(csv_file_path, file_name)
      elsif csv_file_path.match(/dropouts_certified/)
        logger.debug("Storing dropouts_certified, csv_file_path: #{csv_file_path}")
        store_dropout(csv_file_path, file_name)
      else
        delete_file(csv_file_path)
        next
      end
      delete_file(csv_file_path)
    end
  end
  def store_attendance(csv_file_path, file_name)
    CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
      data_source = "#{file_name}##{ind}"
      hash_data = @parser.parse_attendance_csv(row, data_source)
      general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
      hash_data[:general_id] = general_info.id
      @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiAttendance')
    end
    @keeper.flush('WiAttendance')
  end
  def store_dropout(csv_file_path, file_name)
    CSV.foreach(csv_file_path, headers: true).with_index do |row, ind|
      data_source = "#{file_name}##{ind}"
      hash_data = @parser.parse_dropout_csv(row, data_source)
      general_info = @keeper.get_general_info(row[4], row[5], row[8], row[9], data_source)
      hash_data[:general_id] = general_info.id
      @keeper.store(hash_data.merge(md5_hash: create_md5_hash(hash_data)), 'WiDropout')
    end
    @keeper.flush('WiDropout')
  end

  def get_file_list(file_path)
    file_list = []
    Dir["#{file_path}/*"].each do |csv_file_path|
      if File.directory? csv_file_path
        Dir["#{csv_file_path}/*"].each do |path|
          file_list << path
        end
      else
        file_list << csv_file_path
      end
    end
    file_list
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end

  def delete_file(file_path)
    File.delete(file_path) if File.exist?(file_path)
  end
end
