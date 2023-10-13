require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(options = nil)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def scrape(options)
    @keeper.sync_general_info_table
    download(options)
    store(options)
  end

  def download(options=nil)
    @scraper.download(options)
  end

  def store(options)
    download_type_list = %w[Enrollment Assessment Graduation Gifted Attendance Teachers Expenditures]
    download_type_list = options[:type].split(',') if options[:type]
    download_type_list.each do |key|
      path = @scraper.store_file_path(key)
      case key
      when 'Enrollment'
        store_enrollments(path)
      when 'Assessment'
        store_assessments(path)
      when 'Graduation'
        store_graduations(path)
      when 'Gifted'
        store_gifteds(path)
      when 'Attendance'
        store_attendances(path)
      when 'Teachers'
        store_teachers(path)
      when 'Expenditures'
        store_expenditures(path)
      end
    end
  end

  def store_enrollments(folder_path)
    get_file_list(folder_path).each do |path|
      logger.debug("Storing enrollments, path: #{path}")
      hash_array = @parser.parse_enrollment(path)
      hash_array.each do |hash|
        @keeper.store(hash, 'OhEnrollment')
      end
    end
    @keeper.flush('OhEnrollment')
  end

  def store_assessments(folder_path)
    get_file_list(folder_path).each do |path|
      logger.debug("Storing assessments, path: #{path}")
      hash_array = @parser.parse_assessment(path)
      hash_array.each do |hash|
        @keeper.store(hash, 'OhPerformance')
      end
    end
    @keeper.flush('OhPerformance')
  end

  def store_graduations(folder_path)
    get_file_list(folder_path).each do |path|
      logger.debug("Storing graduations, path: #{path}")
      hash_array = @parser.parse_graduation(path)
      hash_array.each do |hash|
        @keeper.store(hash, 'OhGraduation')
      end
    end
    @keeper.flush('OhGraduation')
  end

  def store_gifteds(folder_path)
    get_file_list(folder_path).each do |path|
      logger.debug("Storing gifteds, path: #{path}")
      hash_array = @parser.parse_gifted(path)
      hash_array.each do |hash|
        @keeper.store(hash, 'OhGifted')
      end
    end
    @keeper.flush('OhGifted')
  end

  def store_attendances(folder_path)
    get_file_list(folder_path).each do |path|
      logger.debug("Storing attendances, path: #{path}")
      hash_array = @parser.parse_attendance(path)
      hash_array.each do |hash|
        @keeper.store(hash, 'OhAttendance')
      end
    end
    @keeper.flush('OhAttendance')
  end

  def store_teachers(folder_path)
    get_file_list(folder_path).each do |path|
      logger.debug("Storing teachers, path: #{path}")
      hash_array = @parser.parse_teacher(path)
      hash_array.each do |hash|
        @keeper.store(hash, 'OhEducator')
      end
    end
    @keeper.flush('OhEducator')
  end

  def store_expenditures(folder_path)
    get_file_list(folder_path).each do |path|
      logger.debug("Storing expenditure, path: #{path}")
      hash_array = @parser.parse_expenditure(path)
      hash_array.each do |hash|
        @keeper.store(hash, 'OhExpenditure')
      end
    end
    @keeper.flush('OhExpenditure')
  end

  def get_file_list(folder_path)
    file_list = []
    Dir["#{folder_path}/*"].each do |xlsx_file_path|
      if File.directory? xlsx_file_path
        Dir["#{xlsx_file_path}/*"].each do |path|
          file_list << path
        end
      else
        file_list << xlsx_file_path
      end
    end
    file_list
  end

  def delete_file(file_path)
    File.delete(file_path) if File.exist?(file_path)
  end
end
