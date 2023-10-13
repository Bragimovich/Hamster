require 'fileutils'
require 'roo'

require_relative '../models/il_school_suspension'
# require_relative './main_logger'

class  EndOfYearStudentDisciplineReportParser < Hamster::Harvester
  CREATED_BY = 'Sergii Butrymenko'
  # 2017/18..2019/20
  # HEADERS_ROW = 3
  # HEADERS = ["RCDTS",
  #            "Serving District",
  #            "Serving School",
  #            "Discipline Action Code",
  #            "Discipline Action Desc",
  #            "Total",
  #            "Male",
  #            "Female",
  #            "Hispanic or Latino",
  #            "American Indian or Alaska Native",
  #            "Asian",
  #            "Black or African American",
  #            "Native Hawaiian or Other Pacific Islander",
  #            "White",
  #            "Two or More Races",
  #            "Grade K thru 8",
  #            "Grade 9 thur 12",
  #            "LEP",
  #            "Alcohol",
  #            "Violence With Physical Injury",
  #            "Violence Without Physical Injury",
  #            "Drug Offenses",
  #            "Dangerous Weapon Firearm Other",
  #            "Dangerous Weapon Other",
  #            "Other Reason",
  #            "Tobacco",
  #            "Less than or Equal to 1",
  #            "1.1 - 2.9",
  #            "3.0 - 4.9",
  #            "5.0 - 10",
  #            "Greater than 10"].freeze

  # 2020/21
  HEADERS_ROW = 4
  HEADERS = ['District Name',
             'School Name',
             'ActionCode',
             'ActionDesc',
             'Total Incidents',
             'Total Students',
             'Female',
             'Male',
             'Hispanic or Latino',
             'American Indian or Alaska Native',
             'Black or African American',
             'Asian',
             'Native Hawaiian or Other Pacific Islander',
             'White',
             'Two or More Races',
             'Grade K thru 8',
             'Grade 9 thru 12',
             'EL',
             'Alcohol',
             'Violence With Physical Injury',
             'Violence Without Physical Injury',
             'Drug Offenses',
             'Dangerous Weapon: Firearm',
             'Dangerous Weapon: Other',
             'Other Reason',
             'Tobacco',
             'Less than 1',
             '[1,2)',
             '[2,3)',
             '[3,4)',
             '[4,10]',
             'GREATER THAN 10',
             'NOT REPORTED'].freeze

  def initialize
    super
    @peon = Peon.new(storehouse)
    @file_path = "#{storehouse}store"
    @trash_path = "#{storehouse}trash"
    FileUtils.mkdir_p storehouse + 'log/'
    @logger = Logger.new(storehouse + 'log/' + "parsing_#{Date.today.to_s}.log", 'monthly')
  end

  def parse
    file_list = Dir.glob("#{@file_path}/*.xlsx").sort

    if file_list.empty?
      # MainLogger.logger.error("Downloaded file(s) not found in path #{@file_path}")
      @logger.error("Downloaded file(s) not found in path #{@file_path}")
      return
    end
    # MainLogger.logger.info('Parsing process started.')
    @logger.info('Parsing process started.')

    file_list.each do |file|
      @logger.info("Parsing file: #{file}")
      xlsx = Roo::Spreadsheet.open(file)
      academic_year = xlsx.row(1).first.match(/\d{4}-\d{2}/)[0].sub('-', '-20')
      xlsx_headers = xlsx.row(HEADERS_ROW)

      # puts academic_year.inspect
      # puts file.match(/(\d{4})\D+$/)[1].inspect

      if academic_year[-4..-1] != file.match(/(\d{4})\D+$/)[1]
        @logger.error("Academic year in source XLSX-file doesn't match. File should be checked before proceeding.\n#{file}/*.xlsx")
        raise "Academic year in source XLSX-file doesn't match. File should be checked before proceeding.\n#{file}/*.xlsx"
      end

      if xlsx_headers != HEADERS
        @logger.error("Headers in source XLSX-file were changed. Code fixes should be made before proceeding.\n#{file}/*.xlsx")
        raise "Headers in source XLSX-file were changed. Code fixes should be made before proceeding.\n#{file}/*.xlsx"
      end

      # 2017/18..2019/20
      # xlsx.each_row_streaming(pad_cells: true, offset: HEADERS_ROW) do |row|  # , max_rows: 10
      #   break if row[0].cell_value.upcase.include?('TOTALS')
      #
      #   IlSchoolSuspension.find_or_create_by(
      #     academic_year: academic_year,
      #     rcdts: row[0].cell_value,
      #     district_name: row[1].cell_value,
      #     school_name: row[2].cell_value,
      #     action_code: row[3].cell_value,
      #     action_description: row[4].cell_value,
      #     total_incidents: row[5].cell_value,
      #     male: value_by_type(row[6]),
      #     female: value_by_type(row[7]),
      #
      #     hispanic_or_latino: value_by_type(row[8]),
      #     american_indian_or_alaska_native: value_by_type(row[9]),
      #     asian: value_by_type(row[10]),
      #     black_or_african_american: value_by_type(row[11]),
      #     native_hawaian_or_pacific_islander: value_by_type(row[12]),
      #     white: value_by_type(row[13]),
      #     two_or_more_races: value_by_type(row[14]),
      #
      #     grade_k_thru_8: value_by_type(row[15]),
      #     grade_9_thru_12: value_by_type(row[16]),
      #
      #     EL: value_by_type(row[17]),
      #
      #     alcohol: value_by_type(row[18]),
      #     violence_with_physical_injury: value_by_type(row[19]),
      #     violence_without_physical_injury: value_by_type(row[20]),
      #     drug_offense: value_by_type(row[21]),
      #     dangerous_weapon_firearm: value_by_type(row[22]),
      #     dangerous_weapon_other: value_by_type(row[23]),
      #     other_reason: value_by_type(row[24]),
      #     tobacco: value_by_type(row[25]),
      #
      #     duration_1_day_or_less: value_by_type(row[26]),
      #     duration_1_1_to_2_9_days: value_by_type(row[27]),
      #     duration_3_0_to_4_9_days: value_by_type(row[28]),
      #     duration_5_0_to_10_days: value_by_type(row[29]),
      #     duration_greater_than_10_days: value_by_type(row[30])
      #   )
      # end

      # 2020/21
      xlsx.each_row_streaming(pad_cells: true, offset: 3) do |row|  # , max_rows: 10
        # break if row[0].cell_value.upcase.include?('TOTALS')

        IlSchoolSuspension.find_or_create_by(
          academic_year: academic_year,
          # rcdts: row[0].cell_value,
          district_name: row[0].cell_value,
          school_name: row[1].cell_value,
          action_code: row[2].cell_value,
          action_description: row[3].cell_value,
          total_incidents: row[4].cell_value,
          total_students: row[5].cell_value,
          female: value_by_type(row[6]),
          male: value_by_type(row[7]),

          hispanic_or_latino: value_by_type(row[8]),
          american_indian_or_alaska_native: value_by_type(row[9]),
          black_or_african_american: value_by_type(row[10]),
          asian: value_by_type(row[11]),
          native_hawaian_or_pacific_islander: value_by_type(row[12]),
          white: value_by_type(row[13]),
          two_or_more_races: value_by_type(row[14]),

          grade_k_thru_8: value_by_type(row[15]),
          grade_9_thru_12: value_by_type(row[16]),

          EL: value_by_type(row[17]),

          alcohol: value_by_type(row[18]),
          violence_with_physical_injury: value_by_type(row[19]),
          violence_without_physical_injury: value_by_type(row[20]),
          drug_offense: value_by_type(row[21]),
          dangerous_weapon_firearm: value_by_type(row[22]),
          dangerous_weapon_other: value_by_type(row[23]),
          other_reason: value_by_type(row[24]),
          tobacco: value_by_type(row[25]),

          duration_less_then_1_day: value_by_type(row[26]),
          duration_1_0_to_1_9_days: value_by_type(row[27]),
          duration_2_0_to_2_9_days: value_by_type(row[28]),
          duration_3_0_to_3_9_days: value_by_type(row[29]),
          duration_4_0_to_10_days: value_by_type(row[30]),
          duration_greater_than_10_days: value_by_type(row[31]),
          duration_not_reported: value_by_type(row[32])
        )
      end
      FileUtils.mv(file, file.sub('store', 'trash'))
    rescue ActiveRecord::ActiveRecordError => e
      @logger.error(e)
      raise
    end
  end

  private

  def value_by_type(cell)
    # puts cell.inspect
    if cell.cell_type == :string && cell.cell_value.match?(/[^\d.]/)
      nil
    else
      cell.cell_value
    end
  end
end
