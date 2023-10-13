require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'

class Manager < Hamster::Scraper

  def initialize(**options)
    super
    @peon = Peon.new(storehouse)
    @slack_msg = Slack::Web::Client.new(token: Storage.new.slack)

    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new

    parse_data if options[:store]
    download_data if options[:download]
    send_slack_message if options[:send]
  end

  def get_arr_files_name(folder)
    Dir.entries("#{storehouse}store/#{folder}").select { |f| File.file? File.join("#{storehouse}store/#{folder}", f) }
  end

  def download_data
    data_center_html = @scraper.data_center_page
    @peon.put(content: data_center_html, file: "data_center_reports_page")
    #
    data_archive_html = @scraper.data_archive_page
    @peon.put(content: data_archive_html, file: "data_archive_page")

    @scraper.get_general_info(@peon.give(file: "data_center_reports_page"))
    @scraper.get_attendance_enrollment_info(@peon.give(file: "data_center_reports_page"))
    @scraper.get_ilearn_assessment(@peon.give(file: "data_center_reports_page"), @peon.give(file: "data_archive_page"))
    @scraper.get_istep_plus_assessment(@peon.give(file: "data_center_reports_page"), @peon.give(file: "data_archive_page"))
    @scraper.get_i_am_alternate_assessment(@peon.give(file: "data_center_reports_page"), @peon.give(file: "data_archive_page"))
    @scraper.get_iread_3_assessment(@peon.give(file: "data_center_reports_page"), @peon.give(file: "data_archive_page"))
    @scraper.get_sat_grade_11(@peon.give(file: "data_center_reports_page"))

  end
  def parse_data

    @parser.get_genaral_info(get_arr_files_name('general'))

    @parser.get_enrollment_grade_info(get_arr_files_name('enrollment'))
    @parser.get_enrollment_ethnicity(get_arr_files_name('enrollment'))
    @parser.get_enrollment_by_special_edu_and_ell(get_arr_files_name('enrollment'))

    @parser.get_assessment_ilearn_info(get_arr_files_name('ilearn'))
    @parser.get_assessment_istep_plus(get_arr_files_name('istep'))
    @parser.get_i_am_alternate(get_arr_files_name('i_am'))
    @parser.get_iread_3(get_arr_files_name('iread3'))
    @parser.get_sat(get_arr_files_name('sat'))

    @keeper.finish
  end

  def send_slack_message
      text = "Task #537 US Schools - Indiana education: Check for new data at https://www.in.gov/doe/it/data-center-and-reports/
      If new data is not available, check every month."
      @slack_msg.chat_postMessage(channel: 'U047MQ36JH5',
                                  text: text,
                                  link_names: true
      )
  end


end

