
def parser_iread_3(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_schools_assessment => MD5Hash.new(columns:%i[general_id exam_name grade subject group demographic number_of_students number_tested rate_percent data_source_url]),
    :in_schools_assessment_by_levels => MD5Hash.new(columns:%i[assessment_id level count]),
  }

  arr_names_files.each do |file_name|

    path = "#{storehouse}store/iread3/#{file_name}"
    xlsx = Roo::Spreadsheet.open(path)

    @sheets = xlsx.sheets

    logger.info "*************** Starting parser of #{file_name} ***************"

    hash_in_schools_assessment = {
      # school_year: '',
      # exam_name: 'IREAD-3',
      # grade: '',
      # subject: '',
      # group: '',
      # demographic: '',
      # number_of_students: '',
      # number_tested: '',
      # rate_percent: ''
    }

    if file_name.include?('iread3-final-statewide-student-performance.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        # Create hash for in_schools_assessment table
        hash_in_schools_assessment[:school_year] = get_year(file_name)
        hash_in_schools_assessment[:exam_name] = 'IREAD-3'
        hash_in_schools_assessment[:subject] = @sheets[sheet]

        parser_head = [:number_of_students, :number_tested, :rate_percent]

        (3..xlsx.sheet(@sheets[sheet]).last_row - 3).each do |row_number|

          if xlsx.sheet(@sheets[sheet]).cell(row_number, 1) != nil and xlsx.sheet(@sheets[sheet]).cell(row_number, 1) != 'School Demographic'
            row_data = []

            [2, 3, 4].each do |col|
              row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment[:demographic] = xlsx.sheet(@sheets[sheet]).cell(row_number, 1)
            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end
          end
        end
      end

    elsif file_name.include?('iread3-final-corporation-and-school-results.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        # Create hash for in_schools_assessment table
        hash_in_schools_assessment[:school_year] = get_year(file_name)
        hash_in_schools_assessment[:exam_name] = 'IREAD-3'
        hash_in_schools_assessment[:subject] = @sheets[sheet]

        parser_head = [:number_of_students, :number_tested, :rate_percent]

        (3..xlsx.sheet(@sheets[sheet]).last_row - 3).each do |row_number|

          if @sheets[sheet] != 'School'
            row_data = []

            [3, 4, 5].each do |col|
              row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)
            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 1))

            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end
          else
            row_data = []

            [6, 7, 8].each do |col|
              row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)
            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 4))
            # #
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end
          end
        end
      end

    elsif file_name.include?('iread3-final-disaggregated-report.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics = xlsx.sheet(@sheets[sheet]).row(2).compact.uniq

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:demographic] = demographics[demographic]
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'IREAD-3'
          hash_in_schools_assessment[:subject] = @sheets[sheet]

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          (4..xlsx.sheet(@sheets[sheet]).last_row - 3).each do |row_number|

            if @sheets[sheet] != 'School' and @sheets[sheet] != 'SCHL'
              row_data = []

              # [3 * (demographic + 1), 3 * (demographic + 1) + 1, 3 * (demographic + 1) + 2]
              get_range(start = 3, index = demographic, quantity = 3, space = 0).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end

              result = parser_head.zip(row_data).to_h

              hash_in_schools_assessment = hash_in_schools_assessment.merge(result)
              if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
              end

              hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 1))

              hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
              if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
                @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
                # p hash_in_schools_assessment
              end
            else
              row_data = []

              start_cell = 5
              if file_name == '2022-iread3-final-disaggregated-report.xlsx'
                start_cell = 6
              end

              # p [3 * (demographic + 1) + 3, 3 * (demographic + 1) + 4, 3 * (demographic + 1) + 5]
              get_range(start = start_cell, index = demographic, quantity = 3, space = 0).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end

              result = parser_head.zip(row_data).to_h

              hash_in_schools_assessment = hash_in_schools_assessment.merge(result)
              if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
              end

              sch_id = 3
              if file_name == '2022-iread3-final-disaggregated-report.xlsx'
                sch_id = 4
              end

              hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, sch_id))

              hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
              if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
                @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
                # p hash_in_schools_assessment
              end
            end
            # break
          end
          # break
        end
        # break
      end

    end
  end
end