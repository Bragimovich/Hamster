require_relative '../keeper'


def parser_assessment_istep_plus(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_schools_assessment => MD5Hash.new(columns:%i[general_id exam_name grade subject group demographic number_of_students number_tested rate_percent data_source_url]),
    :in_schools_assessment_by_levels => MD5Hash.new(columns:%i[assessment_id level count]),
  }

  arr_names_files.each do |file_name|

    path = "#{storehouse}store/istep/#{file_name[11..]}"
    xlsx = Roo::Spreadsheet.open(path)
    @sheets = xlsx.sheets

    logger.info "*************** Starting parser of #{file_name} ***************"

    hash_in_schools_assessment = {
      # school_year: '',
      # exam_name: 'ISTEP+',
      # grade: '',
      # subject: '',
      # group: '',
      # demographic: '',
      # number_of_students: '',
      # number_tested: '',
      # rate_percent: ''
    }

    if file_name[11..].include?('-grade10-final-statewide-summary-disaggregated.xlsx') or
       file_name[11..].include?('-grade3-8-final-statewide-summary-disaggregated.xlsx') or
       file_name[11..].include?('_grade10_final_statewide_summary-disaggregated.xlsx')

        hash_in_schools_assessment[:data_source_url] = @domain + file_name

        (0..@sheets.length - 1).each do |sheet|

          logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

          # Create hash for in_schools_assessment table
          subjects = xlsx.sheet(@sheets[sheet]).row(1)[1..].map { |sub| sub.gsub(/\s+/m, ' ').split(' ')[0] }

          hash_in_schools_assessment[:grade] = @sheets[sheet].include?('Grade') ? @sheets[sheet] : nil
          hash_in_schools_assessment[:school_year] = get_year(file_name[11..])
          hash_in_schools_assessment[:exam_name] = 'ISTEP+'

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          (2..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            # if row_number == 20 or row_number == 21 #2021
            if row_number == 17 or row_number == 18 #2019--2018
              next
            elsif xlsx.sheet(@sheets[sheet]).cell(row_number, 1) == nil
              break
            else
              (0..2).each do |i|
                row_data = []
                get_range(start = 2, index = i, quantity = 3, space = 0).each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end

                result = parser_head.zip(row_data).to_h

                hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

                hash_in_schools_assessment[:subject] = subjects[3 * i + 2] == 'Both' ? 'Both ELA and Math' : subjects[3 * i + 2]
                if row_number < 19
                  hash_in_schools_assessment[:demographic] = xlsx.sheet(@sheets[sheet]).cell(row_number, 1)
                end

                if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                  hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
                end

                if row_number >= 19 and xlsx.sheet(@sheets[sheet]).cell(row_number, 1).include?('Grade')
                  hash_in_schools_assessment[:grade] = xlsx.sheet(@sheets[sheet]).cell(row_number, 1)
                  hash_in_schools_assessment[:demographic] = nil
                end

                # hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number,1))
                hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

                if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
                  @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
                  # p hash_in_schools_assessment
                end
              end
              # break
            end
          end
        end

    elsif file_name[11..].include?('-2018-grade10-final-corporation.xlsx') or
          file_name[11..].include?('_grade10_final_corporation.xlsx')

        hash_in_schools_assessment[:data_source_url] = @domain + file_name

        (0..@sheets.length - 1).each do |sheet|

          logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

          subject_row = 2
          if file_name[11..] == 'istep-2021-grade10-final-corporation.xlsx'
            subject_row = 6
          end
          if file_name[11..] == 'istep-2019-grade10-final-corporation.xlsx'
            subject_row = 2
          end

          subjects = xlsx.sheet(@sheets[sheet]).row(subject_row)[2..].map { |sub| sub.gsub(/\s+/m, ' ').split(' ')[0] }

          # 2018
          grades = xlsx.sheet(@sheets[sheet]).row(1).compact

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:grade] = 'Grade 10'
          hash_in_schools_assessment[:school_year] = get_year(file_name[11..])
          hash_in_schools_assessment[:exam_name] = 'ISTEP+'

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 3
          if file_name[11..] == 'istep-2021-grade10-final-corporation.xlsx'
            start_row = 7
          end
          if file_name[11..] == 'istep-2019-grade10-final-corporation.xlsx'
            start_row = 3
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

            (0..2).each do |i|
              row_data = []
              get_range(start = 3, index = i, quantity = 3, space = 0).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end

              result = parser_head.zip(row_data).to_h

              hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

              hash_in_schools_assessment[:subject] = subjects[3 * i + 2] == 'Both' ? 'Both ELA and Math' : subjects[3 * i + 2]
              # hash_in_schools_assessment[:demographic] = xlsx.sheet(@sheets[sheet]).cell(row_number, 1)

              if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
              end

              hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 1))
              hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

              if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
                @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
                p hash_in_schools_assessment
              end
            end
            # break
          end
        end

    elsif file_name[11..].include?('-grade10-final-corporation-disaggregated.xlsx')  or
          file_name[11..].include?('-grade3-8-final-corporation-disaggregated.xlsx')

        hash_in_schools_assessment[:data_source_url] = @domain + file_name

        (0..@sheets.length - 1).each do |sheet|

          logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

          # Create hash for in_schools_assessment table

          demographic_row = 1
          if file_name[11..] == 'istep-2021-grade10-final-corporation-disaggregated.xlsx'
            demographic_row = 5
          end
          if file_name[11..] == 'istep-2019-grade10-final-corporation-disaggregated.xlsx' or
            file_name[11..] == 'ISTEP-2018-Grade3-8-Final-Corporation-Disaggregated.xlsx'

            demographic_row = 1
          end

          demographics = xlsx.sheet(@sheets[sheet]).row(demographic_row).compact

          (0..demographics.length - 1).each do |demographic|

            subject_row = 2
            if file_name[11..] == 'istep-2021-grade10-final-corporation-disaggregated.xlsx'
              subject_row = 6
            end
            if file_name[11..] == 'istep-2019-grade10-final-corporation-disaggregated.xlsx' or
              file_name[11..] == 'istep-2018-grade3-8-final-corporation-disaggregated.xlsx'
              subject_row = 2
            end

            subjects = xlsx.sheet(@sheets[sheet]).row(subject_row)[2..].map { |sub| sub.gsub(/\s+/m, ' ').split(' ')[0] }

            hash_in_schools_assessment[:demographic] = demographics[demographic]
            hash_in_schools_assessment[:grade] = 'Grade 10'
            hash_in_schools_assessment[:school_year] = get_year(file_name[11..])
            hash_in_schools_assessment[:exam_name] = 'ISTEP+'
            hash_in_schools_assessment[:group] = @sheets[sheet]

            parser_head = [:number_of_students, :number_tested, :rate_percent]

            start_row = 3
            if file_name[11..] == 'istep-2021-grade10-final-corporation-disaggregated.xlsx'
              start_row = 7
            end
            if file_name[11..] == 'istep-2019-grade10-final-corporation-disaggregated.xlsx' or
              file_name[11..] == 'istep-2018-grade3-8-final-corporation-disaggregated.xlsx'

              start_row = 3
            end

            (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

              (0..2).each do |i|

                row_data = []

                [3 * i + 3 + (demographic * 9), 3 * i + 4 + (demographic * 9), 3 * i + 5 + (demographic * 9)].each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end

                result = parser_head.zip(row_data).to_h

                hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

                hash_in_schools_assessment[:subject] = subjects[3 * i + 2] == 'Both' ? 'Both ELA and Math' : subjects[3 * i + 2]

                if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                  hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
                end

                hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 1))
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

    elsif file_name[11..].include?('-grade10-final-school.xlsx')  or
          file_name[11..].include?('_2017_grade10_final_school.xlsx')

        hash_in_schools_assessment[:data_source_url] = @domain + file_name

        (0..@sheets.length - 1).each do |sheet|

          logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

          # Create hash for in_schools_assessment table
          subject_row = 2
          if file_name[11..] == 'istep-2021-grade10-final-school.xlsx'
            subject_row = 6
          end
          if file_name[11..] == 'istep-2019-grade10-final-school.xlsx'
            subject_row = 2
          end

          subjects = xlsx.sheet(@sheets[sheet]).row(subject_row)[4..].map { |sub| sub.gsub(/\s+/m, ' ').split(' ')[0] }

          hash_in_schools_assessment[:grade] = 'Grade 10'
          hash_in_schools_assessment[:school_year] = get_year(file_name[11..])
          hash_in_schools_assessment[:exam_name] = 'ISTEP+'

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 3
          if file_name[11..] == 'istep-2021-grade10-final-school.xlsx'
            start_row = 7
          end
          if file_name[11..] == 'istep-2019-grade10-final-school.xlsx'
            start_row = 3
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

            (0..2).each do |i|

              row_data = []

              get_range(start = 5, index = i, quantity = 3, space = 0).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end

              result = parser_head.zip(row_data).to_h

              hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

              hash_in_schools_assessment[:subject] = subjects[3 * i + 2] == 'Both' ? 'Both ELA and Math' : subjects[3 * i + 2]

              if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
              end

              hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
              hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

              if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
                @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
                # p hash_in_schools_assessment
              end
            end
            # break
          end
        end

    elsif file_name[11..].include?('-grade10-final-school-disaggregated.xlsx')  or
          file_name[11..].include?('-grade3-8-final-school-disaggregated.xlsx')

        hash_in_schools_assessment[:data_source_url] = @domain + file_name

        (0..@sheets.length - 1).each do |sheet|

          logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

          # Create hash for in_schools_assessment table
          demographic_row = 1
          if file_name[11..] == 'istep-2021-grade10-final-school-disaggregated.xlsx'
            demographic_row = 5
          end
          if file_name[11..] == 'istep-2019-grade10-final-school-disaggregated.xlsx'
            demographic_row = 1
          end

          demographics = xlsx.sheet(@sheets[sheet]).row(demographic_row).compact

          (0..demographics.length - 1).each do |demographic|

            subject_row = 2
            if file_name[11..] == 'istep-2021-grade10-final-school-disaggregated.xlsx'
              subject_row = 6
            end
            if file_name[11..] == 'istep-2019-grade10-final-school-disaggregated.xlsx'
              subject_row = 2
            end

            subjects = xlsx.sheet(@sheets[sheet]).row(subject_row)[2..].map { |sub| sub.gsub(/\s+/m, ' ').split(' ')[0] }

            hash_in_schools_assessment[:demographic] = demographics[demographic]
            hash_in_schools_assessment[:grade] = 'Grade 10'
            hash_in_schools_assessment[:school_year] = get_year(file_name[11..])
            hash_in_schools_assessment[:exam_name] = 'ISTEP+'
            hash_in_schools_assessment[:group] = @sheets[sheet]

            parser_head = [:number_of_students, :number_tested, :rate_percent]

            start_row = 3
            if file_name[11..] == 'istep-2021-grade10-final-school-disaggregated.xlsx'
              start_row = 7
            end
            if file_name[11..] == 'istep-2019-grade10-final-school-disaggregated.xlsx'
              start_row = 3
            end

            (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

              (0..2).each do |i|

                row_data = []

                [3 * i + 5 + (demographic * 9), 3 * i + 6 + (demographic * 9), 3 * i + 7 + (demographic * 9)].each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end

                result = parser_head.zip(row_data).to_h

                hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

                hash_in_schools_assessment[:subject] = subjects[3 * i + 2] == 'Both' ? 'Both ELA and Math' : subjects[3 * i + 2]

                if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                  hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
                end

                hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
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

    elsif file_name[11..] == 'istep-2018-grade3-8-final-science-and-social-studies.xlsx' or
          file_name[11..] == 'istep-2018-grade10-final-science.xlsx' or
          file_name[11..] == 'istep-2017-grade10-final-science-results.xlsx'

        hash_in_schools_assessment[:data_source_url] = @domain + file_name

        (0..@sheets.length - 1).each do |sheet|

          logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

          # Create hash for in_schools_assessment table

          grades = xlsx.sheet(@sheets[sheet]).row(1).compact

          hash_in_schools_assessment[:subject] = @sheets[sheet].split(/[ _]/)[1..].join(' ')
          hash_in_schools_assessment[:school_year] = get_year(file_name[11..])
          hash_in_schools_assessment[:exam_name] = 'ISTEP+'

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          (3..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

            (0..grades.length - 1).each do |grade|

              row_data = []

              start_col = hash_in_schools_assessment[:subject].include?('SCH') ? 5 : 3

              get_range(start = start_col, index = grade, quantity = 3, space = 0).each do |col|

                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end

              result = parser_head.zip(row_data).to_h

              hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

              hash_in_schools_assessment[:grade] = grades[grade]

              if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
              end

              id_col = hash_in_schools_assessment[:subject].include?('SCH') ? 3 : 1

              hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, id_col))
              hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

              if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
                @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
                # p hash_in_schools_assessment
              end
            end
            # break
          end
        end

    elsif file_name[11..].include?('-grade3-8-final-statewide-summary.xlsx')  or
          file_name[11..].include?('-grade10-final-statewide-summary.xlsx')  or
          file_name[11..].include?('_2017_grade10_final_statewide_summary.xlsx')

        hash_in_schools_assessment[:data_source_url] = @domain + file_name

        (0..@sheets.length - 1).each do |sheet|

          logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

          # Create hash for in_schools_assessment table
          subjects = xlsx.sheet(@sheets[sheet]).row(2)[1..].map { |sub| sub.gsub(/\s+/m, ' ').split(' ')[0] }
          school_years = xlsx.sheet(@sheets[sheet]).row(1).compact

          # hash_in_schools_assessment[:school_year] = get_year(file_name[11..])
          hash_in_schools_assessment[:exam_name] = 'ISTEP+'

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          (3..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            # if row_number == 20 or row_number == 21 #2021
            if xlsx.sheet(@sheets[sheet]).cell(row_number, 1) == nil
              break
            else
              (0..1).each do |i|
                row_data = []
                get_range(start = 2, index = i, quantity = 3, space = 0).each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end

                result = parser_head.zip(row_data).to_h

                hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

                hash_in_schools_assessment[:school_year] = school_years[i]
                hash_in_schools_assessment[:grade] = xlsx.sheet(@sheets[sheet]).cell(row_number, 1)
                hash_in_schools_assessment[:subject] = subjects[3 * i + 2]
                if subjects[3 * i + 2] == 'Both'
                  hash_in_schools_assessment[:subject] = 'Both ELA and Math'
                end
                if subjects[3 * i + 2] == 'Social'
                  hash_in_schools_assessment[:subject] = 'Social Studies'
                end

                if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                  hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
                end

                hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 1))
                hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

                if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
                  @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
                  # p hash_in_schools_assessment
                end
              end
              # break
            end
          end
        end

    elsif file_name[11..].include?('-grade3-8-final-corporation.xlsx')  or
          file_name[11..].include?('-grade3-8-final-school.xlsx')  or

        hash_in_schools_assessment[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        # Create hash for in_schools_assessment table
        grades_row = 1

        grades = xlsx.sheet(@sheets[sheet]).row(grades_row).compact

        (0..grades.length - 1).each do |grade|

          subject_row = 2

          subjects = xlsx.sheet(@sheets[sheet]).row(subject_row)[2..].map { |sub| sub.gsub(/\s+/m, ' ').split(' ')[0] }

          hash_in_schools_assessment[:grade] = grades[grade]
          hash_in_schools_assessment[:school_year] = get_year(file_name[11..])
          hash_in_schools_assessment[:exam_name] = 'ISTEP+'
          hash_in_schools_assessment[:group] = @sheets[sheet]

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 3

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

            (0..2).each do |i|

              row_data = []

              arr = file_name[11..].include?('school') ?
                      [3 * i + 5 + (grade * 9), 3 * i + 6 + (grade * 9), 3 * i + 7 + (grade * 9)] :
                      [3 * i + 3 + (grade * 9), 3 * i + 4 + (grade * 9), 3 * i + 5 + (grade * 9)]

              arr.each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end

              result = parser_head.zip(row_data).to_h

              hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

              hash_in_schools_assessment[:subject] = subjects[3 * i + 2] == 'Both' ? 'Both ELA and Math' : subjects[3 * i + 2]

              if hash_in_schools_assessment[:rate_percent].is_a?(Float)
                hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
              end

              cell = file_name[11..].include?('School') ? 3 : 1
              hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, cell))
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