require_relative '../keeper'


def parser_assessment_ilearn_info(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_schools_assessment => MD5Hash.new(columns:%i[general_id exam_name grade subject group demographic number_of_students number_tested rate_percent data_source_url]),
    :in_schools_assessment_by_levels => MD5Hash.new(columns:%i[assessment_id level count]),
  }

  arr_names_files.each do |file_name|

    logger.info "*************** Starting parser of #{file_name} ***************"

    path = "#{storehouse}store/ilearn/#{file_name}"
    xlsx = Roo::Spreadsheet.open(path)
    @sheets = xlsx.sheets

    hash_in_schools_assessment = {
      # general_id: '',
      # school_year: '',
      # exam_name: 'ILEARN',
      # grade: '',
      # subject: '',
      # group: '',
      # demographic: '',
      # number_of_students: '',
      # number_tested: '',
      # rate_percent: ''
    }
    hash_in_schools_assessment_by_levels = {
      # assessment_id: '',
      # level: '',
      # count: '',
    }

    if file_name.include?('-grade3-8-final-statewide-summary-disaggregated.xlsx')

      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        hash_in_schools_assessment[:demographic] = 'Student Demographic'
        if @sheets[sheet] == 'ELA & Math'
          hash_in_schools_assessment[:number_of_students] = "Both #{@sheets[sheet]}\nTotal\nProficient"
          hash_in_schools_assessment[:number_tested] = "Both #{@sheets[sheet]}\nTotal\nTested"
          hash_in_schools_assessment[:rate_percent] = "Both #{@sheets[sheet]}\nProficient \n%"
        else
          hash_in_schools_assessment[:number_of_students] = "#{@sheets[sheet]}\nTotal\nProficient"
          hash_in_schools_assessment[:number_tested] = "#{@sheets[sheet]}\nTotal\nTested"
          hash_in_schools_assessment[:rate_percent] = "#{@sheets[sheet]}\nProficient \n%"
        end

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        # Create hash for in_schools_assessment table
        xlsx.sheet(@sheets[sheet]).each(hash_in_schools_assessment) do |hash|

          hash[:school_year] = get_year(file_name)
          hash[:exam_name] = 'ILEARN'
          hash[:subject] = @sheets[sheet]
          hash[:data_source_url] = @domain + file_name

          if hash[:demographic] == nil
            break
          else
            if hash[:demographic] != "Student Demographic"
              if hash[:rate_percent].is_a?(Float)
                hash[:rate_percent] = (hash[:rate_percent] * 100).round(1)
              end
              hash[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash)
              @keeper.save_on_in_schools_assessment(hash)
              # puts hash.inspect
            end
          end
          # break
        end

        start_row = 19
        if file_name == 'ilearn-2022-grade3-8-final-statewide-summary-disaggregated.xlsx' or
          file_name == 'ilearn-2019-grade3-8-final-statewide-summary-disaggregated.xlsx'
          start_row = 19
        end
        if file_name == 'ilearn-2021-grade3-8-final-statewide-summary-disaggregated.xlsx'
          start_row = 22
        end

        (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
          hash_in_schools_assessment = {
            # school_year: '',
            # exam_name: 'ILEARN',
            # grade: '',
            # subject: '',
            # group: '',
            # demographic: '',
            # number_of_students: '',
            # number_tested: '',
            # rate_percent: ''
          }

          cells = xlsx.sheet(@sheets[sheet]).row(row_number)

          if cells[0].nil?
            break
          else
            if @sheets[sheet] != 'ELA & Math'
              hash_in_schools_assessment = {
                school_year: get_year(file_name),
                exam_name: 'ILEARN',
                grade: cells[0],
                subject: @sheets[sheet],
                # group: '',
                # demographic: '',
                number_of_students: cells[5],
                number_tested: cells[6],
                rate_percent: if cells[7].is_a?(Float) then (cells[7] * 100).round(1) end,
                data_source_url: @domain + file_name
              }
            else
              hash_in_schools_assessment = {
                school_year: get_year(file_name),
                exam_name: 'ILEARN',
                grade: cells[0],
                subject: @sheets[sheet],
                # group: '',
                # demographic: '',
                number_of_students: cells[1],
                number_tested: cells[2],
                rate_percent: if cells[3].is_a?(Float) then (cells[3] * 100).round(1) end,
                data_source_url: @domain + file_name
              }
            end
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
            @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
            # p hash_in_schools_assessment
          end
        end

        # Create hash for in_schools_assessment_by_levels table
        headings = xlsx.sheet(@sheets[sheet]).row(1)[1..4].map { |name| name.gsub("\n", " ").gsub(@sheets[sheet], "").strip }
        # headings = xlsx.sheet(@sheets[sheet]).row(1)[1..4].map {|name| name.gsub("\n", " ").split(' ')[-2..].join(' ')}

        if @sheets[sheet] != 'ELA & Math'
          (2..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            cells = xlsx.sheet(@sheets[sheet]).row(row_number)
            if cells[0].nil?
              break
            else
              (0..3).each do |i|

                hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + 1]

                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
                @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                # p hash_in_schools_assessment_by_levels
              end
            end
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            cells = xlsx.sheet(@sheets[sheet]).row(row_number)
            if cells [0] != nil
              (0..3).each do |i|
                if cells [i + 1] != nil
                  hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id({ grade: cells[0], number_of_students: cells[5], number_tested: cells[6], rate_percent: if cells[7].is_a?(Float) then
                                                                                                                                                                                             (cells[7] * 100).round(1)
                                                                                                                                                                                           end })
                  hash_in_schools_assessment_by_levels[:level] = headings[i]
                  hash_in_schools_assessment_by_levels[:count] = cells[i + 1]

                  hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  # p hash_in_schools_assessment_by_levels
                end
              end
            end
          end
        end
      end

    elsif file_name.include?('-grade3-8-final-corporation.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        grades_row = 4
        if file_name == 'ilearn-2022-grade3-8-final-corporation.xlsx'
          grades_row = 4
        end
        if file_name == 'ilearn-2021-grade3-8-final-corporation.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation.xlsx'
          grades_row = 5
        end

        grades = xlsx.sheet(@sheets[sheet]).row(grades_row).compact

        (0..grades.length - 1).each do |grade|

          # Create hash for in_schools_assessment table

          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:grade] = grades[grade]
          hash_in_schools_assessment[:exam_name] = 'ILEARN'
          hash_in_schools_assessment[:subject] = @sheets[sheet]

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ileaarn-2022-grade3-8-final-corporation.xlsx'
            start_row = 6
          end
          if file_name == 'ileaarn-2021-grade3-8-final-corporation.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []

            if @sheets[sheet] != 'ELA & Math'
              [7 * (grade + 1), 7 * (grade + 1) + 1, 7 * (grade + 1) + 2].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              [3 * (grade + 1), 3 * (grade + 1) + 1, 3 * (grade + 1) + 2].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 1))

            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              #   p hash_in_schools_assessment
            end

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 5
            if file_name == 'ilearn-2022-grade3-8-final-corporation.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-grade3-8-final-corporation.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[2..5].map { |name| name.gsub("\n", " ").gsub(@sheets[sheet], "").strip }
            # headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[2..5].map {|name| name.gsub("\n", " ").split(' ')[-2..].join(' ')}

            if @sheets[sheet] != 'ELA & Math'
              cells = xlsx.sheet(@sheets[sheet]).row(row_number)

              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..3).each do |i|

                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (grade * 7) + 2]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  # p hash_in_schools_assessment_by_levels
                end
              end
            end
            # If ON BREAK -> One Grade if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    elsif file_name.include?('-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics_row = 4
        if file_name == 'ilearn-2022-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx'
          demographics_row = 4
        end
        if file_name == 'ilearn-2021-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx'
          demographics_row = 5
        end

        demographics = xlsx.sheet(@sheets[sheet]).row(demographics_row).compact

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table

          hash_in_schools_assessment[:demographic] = demographics[demographic]
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'ILEARN'

          unless @sheets[sheet].include?("ELA & Math") or @sheets[sheet].include?('Social Studies')
            subject = @sheets[sheet].split(/\s+/, 2)[0]
            group = @sheets[sheet].split(/\s+/, 2)[1]
          else
            substr = @sheets[sheet][/ELA & Math|Social Studies/]
            subject = substr
            group = @sheets[sheet].split(/#{substr}\s*/)[1]
          end

          hash_in_schools_assessment[:subject] = subject
          hash_in_schools_assessment[:group] = group

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ilearn-2022-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx'
            start_row = 6
          end
          if file_name == 'ilearn-2021-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []

            unless @sheets[sheet].include?('ELA & Math')
              [7 * (demographic + 1), 7 * (demographic + 1) + 1, 7 * (demographic + 1) + 2].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              [3 * (demographic + 1), 3 * (demographic + 1) + 1, 3 * (demographic + 1) + 2].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
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
              #   p hash_in_schools_assessment
            end

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 5
            if file_name == 'ilearn-2022-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation-frl-se-ell-disaggregated.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[2..5].map { |name|
              unless @sheets[sheet].include?("ELA & Math") or @sheets[sheet].include?('Social Studies') or @sheets[sheet].include?('SS')
                name.gsub("\n", " ").gsub(@sheets[sheet].split(/\s+/, 2)[0], "").strip
              else
                if @sheets[sheet].include?('SS')
                  substr = "Social Studies"
                else
                  substr = @sheets[sheet][/ELA & Math|Social Studies/]
                end
                name.gsub("\n", " ").gsub(substr, "").strip
              end
            }

            # headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[2..5].map {|name| name.gsub("\n", " ").split(' ')[-2..].join(' ')}

            unless @sheets[sheet].include?('ELA & Math')
              cells = xlsx.sheet(@sheets[sheet]).row(row_number)

              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..3).each do |i|
                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (demographic * 7) + 2]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  #   p hash_in_schools_assessment_by_levels
                end
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    elsif file_name.include?('-grade3-8-final-corporation-ethnicity-and-gender-disaggregated.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics_row = 4
        if file_name == 'ilearn-2022-grade3-8-final-corporation-ethnicity-and-gender-disaggregated.xlsx'
          demographics_row = 4
        end
        if file_name == 'ilearn-2021-grade3-8-final-corporation-ethnicity-and-gender-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation-ethnicity-and-gender-disaggregated.xlsx'
          demographics_row = 5
        end

        demographics = xlsx.sheet(@sheets[sheet]).row(demographics_row).compact

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:demographic] = demographics[demographic]
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          # hash_in_schools_assessment[:grade] = demographics[demographic]
          hash_in_schools_assessment[:exam_name] = 'ILEARN'

          unless @sheets[sheet].include?("ELA & Math") or @sheets[sheet].include?('Social Studies')
            subject = @sheets[sheet].split(/\s+/, 2)[0]
            group = @sheets[sheet].split(/\s+/, 2)[1]
          else
            substr = @sheets[sheet][/ELA & Math|Social Studies/]
            subject = substr
            group = @sheets[sheet].split(/#{substr}\s*/)[1]
          end

          hash_in_schools_assessment[:subject] = subject
          hash_in_schools_assessment[:group] = group

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ilearn-2022-grade3-8-final-corporation-gender-and-ethnicity-disaggregated.xlsx'
            start_row = 6
          end
          if file_name == 'ilearn-2021-grade3-8-final-corporation-gender-and-ethnicity-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation-ethnicity-and-gender-disaggregated.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

            row_data = []

            unless @sheets[sheet].include?('ELA & Math')
              [7 * (demographic + 1), 7 * (demographic + 1) + 1, 7 * (demographic + 1) + 2].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              [3 * (demographic + 1), 3 * (demographic + 1) + 1, 3 * (demographic + 1) + 2].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
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

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 5
            if file_name == 'ilearn-2022-grade3-8-final-corporation-gender-and-ethnicity-disaggregated.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-grade3-8-final-corporation-gender-and-ethnicity-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-corporation-ethnicity-and-gender-disaggregated.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[2..5].map { |name|

              unless @sheets[sheet].include?("ELA & Math") or @sheets[sheet].include?('Social Studies') or @sheets[sheet].include?('SS')
                name.gsub("\n", " ").gsub(@sheets[sheet].split(/\s+/, 2)[0], "").strip
              else
                if @sheets[sheet].include?('SS')
                  substr = "Social Studies"
                else
                  substr = @sheets[sheet][/ELA & Math|Social Studies/]
                end
                name.gsub("\n", " ").gsub(substr, "").strip
              end
            }

            # headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[2..5].map {|name| name.gsub("\n", " ").split(' ')[-2..].join(' ')}

            unless @sheets[sheet].include?('ELA & Math')

              cells = xlsx.sheet(@sheets[sheet]).row(row_number)

              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..3).each do |i|
                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (demographic * 7) + 2]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  #   p hash_in_schools_assessment_by_levels
                end
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    elsif file_name.include?('-grade3-8-final-school.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        grades_row = 4
        if file_name == 'ilearn-2022-grade3-8-final-school.xlsx'
          grades_row = 4
        end
        if file_name == 'ilearn-2021-grade3-8-final-school.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school.xlsx'
          grades_row = 5
        end

        grades = xlsx.sheet(@sheets[sheet]).row(grades_row).compact

        (0..grades.length - 1).each do |grade|

          # Create hash for in_schools_assessment table

          hash_in_schools_assessment[:grade] = grades[grade]
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'ILEARN'
          hash_in_schools_assessment[:subject] = @sheets[sheet]

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ilearn-2022-grade3-8-final-school.xlsx'
            start_row = 6
          end
          if file_name == 'ilearn-2021-grade3-8-final-school.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []

            if @sheets[sheet] != 'ELA & Math'
              [7 * (grade + 1) + 2, 7 * (grade + 1) + 3, 7 * (grade + 1) + 4].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              [3 * (grade + 1) + 2, 3 * (grade + 1) + 3, 3 * (grade + 1) + 4].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)
            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 5
            if file_name == 'ilearn-2022-grade3-8-final-school.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-grade3-8-final-school.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[4..7].map { |name| name.gsub("\n", " ").gsub(@sheets[sheet], "").strip }

            if @sheets[sheet] != 'ELA & Math'
              cells = xlsx.sheet(@sheets[sheet]).row(row_number)

              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..3).each do |i|

                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (grade * 7) + 4]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  #   p hash_in_schools_assessment_by_levels
                end
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    elsif file_name.include?('-grade3-8-final-school-frl-se-ell-disaggregated.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics_row = 4
        if file_name == 'ilearn-2022-grade3-8-final-school-frl-se-ell-disaggregated.xlsx'
          demographics_row = 4
        end
        if file_name == 'ilearn-2021-grade3-8-final-school-frl-se-ell-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school-frl-se-ell-disaggregated.xlsx'
          demographics_row = 5
        end

        demographics = xlsx.sheet(@sheets[sheet]).row(demographics_row).compact

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:demographic] = demographics[demographic]
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'ILEARN'

          unless @sheets[sheet].include?("ELA & Math") or @sheets[sheet].include?('Social Studies')
            subject = @sheets[sheet].split(/\s+/, 2)[0]
            group = @sheets[sheet].split(/\s+/, 2)[1]
          else
            substr = @sheets[sheet][/ELA & Math|Social Studies/]
            subject = substr
            group = @sheets[sheet].split(/#{substr}\s*/)[1]
          end

          hash_in_schools_assessment[:subject] = subject
          hash_in_schools_assessment[:group] = group

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ilearn-2022-grade3-8-final-school-frl-se-ell-disaggregated.xlsx'
            start_row = 6
          end
          if file_name == 'ilearn-2021-grade3-8-final-school-frl-se-ell-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school-frl-se-ell-disaggregated.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []

            unless @sheets[sheet].include?('ELA & Math')
              [7 * (demographic + 1) + 2, 7 * (demographic + 1) + 3, 7 * (demographic + 1) + 4].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              [3 * (demographic + 1) + 2, 3 * (demographic + 1) + 3, 3 * (demographic + 1) + 4].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)
            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end

            # Create hash for in_schools_assessment_by_levels table
            headings_row = 5
            if file_name == 'ilearn-2022-grade3-8-final-school-frl-se-ell-disaggregated.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-grade3-8-final-school-frl-se-ell-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school-frl-se-ell-disaggregated.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[4..7].map { |name| name.gsub("\n", " ").split(' ')[-2..].join(' ') }

            unless @sheets[sheet].include?('ELA & Math')

              cells = xlsx.sheet(@sheets[sheet]).row(row_number)

              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..3).each do |i|
                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (demographic * 7) + 4]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  # p hash_in_schools_assessment_by_levels
                end
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    elsif file_name.include?('-grade3-8-final-school-ethnicity-and-gender-disaggregated.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics_row = 4
        if file_name == 'ilearn-2022-grade3-8-final-school-gender-and-ethnicity-disaggregated.xlsx'
          demographics_row = 4
        end
        if file_name == 'ilearn-2021-grade3-8-final-school-gender-and-ethnicity-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school-ethnicity-and-gender-disaggregated.xlsx'
          demographics_row = 5
        end

        demographics = xlsx.sheet(@sheets[sheet]).row(demographics_row).compact

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:demographic] = demographics[demographic]
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'ILEARN'

          unless @sheets[sheet].include?("ELA & Math") or @sheets[sheet].include?('Social Studies')
            subject = @sheets[sheet].split(/\s+/, 2)[0]
            group = @sheets[sheet].split(/\s+/, 2)[1]
          else
            substr = @sheets[sheet][/ELA & Math|Social Studies/]
            subject = substr
            group = @sheets[sheet].split(/#{substr}\s*/)[1]
          end

          hash_in_schools_assessment[:subject] = subject
          hash_in_schools_assessment[:group] = group

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ilearn-2022-grade3-8-final-school-gender-and-ethnicity-disaggregated.xlsx'
            start_row = 6
          end
          if file_name == 'ilearn-2021-grade3-8-final-school-gender-and-ethnicity-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school-ethnicity-and-gender-disaggregated.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []

            unless @sheets[sheet].include?('ELA & Math')
              get_range(start = 9, index = demographic, quantity = 3, space = 4).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              get_range(start = 5, index = demographic, quantity = 3, space = 0).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)
            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 5
            if file_name == 'ilearn-2022-grade3-8-final-school-gender-and-ethnicity-disaggregated.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-grade3-8-final-school-gender-and-ethnicity-disaggregated.xlsx' or file_name == 'ilearn-2019-grade3-8-final-school-ethnicity-and-gender-disaggregated.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[4..7].map { |name| name.gsub("\n", " ").split(' ')[-2..].join(' ') }

            unless @sheets[sheet].include?('ELA & Math')

              cells = xlsx.sheet(@sheets[sheet]).row(row_number)

              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..3).each do |i|
                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (demographic * 7) + 4]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  # p hash_in_schools_assessment_by_levels
                end
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    elsif file_name.include?('-biology-final-statewide-summary-disaggregated.xlsx')

      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        sub_and_gr = @sheets[sheet].scan(/\b[\w+&.]+\b/)

        hash_in_schools_assessment[:demographic] = 'Student Demographic'

        xlsx.sheet(@sheets[sheet]).cell(1, 2).scan(/\b[\w+&.]+\b/)[0] == 'Biology' ? sub_and_gr[0] = 'Biology' : sub_and_gr[0] = 'Science'
        hash_in_schools_assessment[:number_of_students] = "#{sub_and_gr[0]}\nTotal\nProficient"
        hash_in_schools_assessment[:number_tested] = "#{sub_and_gr[0]}\nTotal\nTested"
        hash_in_schools_assessment[:rate_percent] = "#{sub_and_gr[0]}\nProficient \n%"
        sub_and_gr[0] = 'Biology'

        arr_md5_hash = []

        # Create hash for in_schools_assessment table
        xlsx.sheet(@sheets[sheet]).each(hash_in_schools_assessment) do |hash|

          hash[:data_source_url] = @domain + file_name
          hash[:school_year] = get_year(file_name)
          hash[:exam_name] = 'ILEARN'
          hash[:subject] = sub_and_gr[0]
          hash[:group] = sub_and_gr[1..].join(' ')

          if hash[:demographic] == nil
            break
          else
            if hash[:demographic] != "Student Demographic"
              unless hash_in_schools_assessment[:rate_percent].is_a?(Float)
                hash[:rate_percent] = (hash[:rate_percent] * 100).round(1)
              end

              hash[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))

              hash[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash)
              arr_md5_hash.push(hash[:md5_hash])

              if @keeper.existed_data_in_schools_assessment(hash).nil?
                @keeper.save_on_in_schools_assessment(hash)
                # puts hash.inspect
              end
            end
          end
        end

        start_row = 19

        hash_in_schools_assessment = {
          # school_year: '',
          # exam_name: 'ILEARN',
          # grade: '',
          # subject: '',
          # group: '',
          # demographic: '',
          # number_of_students: '',
          # number_tested: '',
          # rate_percent: ''
        }

        (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
          cells = xlsx.sheet(@sheets[sheet]).row(row_number)
          if cells[1].nil?
            break
          else
            hash_in_schools_assessment = {
              demographic: cells[0],
              school_year: get_year(file_name),
              exam_name: 'ILEARN',
              subject: sub_and_gr[0],
              group: sub_and_gr[1..].join(' '),
              number_of_students: cells[5],
              number_tested: cells[6],
              rate_percent: if cells[7].is_a?(Float) then (cells[7] * 100).round(1) end,
              data_source_url: @domain + file_name,
            }
          end
          hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

          if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
            @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
            # puts hash_in_schools_assessment
          end
        end

        # Create hash for in_schools_assessment_by_levels table
        headings = xlsx.sheet(@sheets[sheet]).row(1)[1..4].map { |name| name.gsub("\n", " ").gsub(sub_and_gr[0], "").strip }

        (0..14).each do |row_number|
          cells = xlsx.sheet(@sheets[sheet]).row(row_number + 2)
          hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: arr_md5_hash[row_number])

          (0..3).each do |i|
            hash_in_schools_assessment_by_levels[:level] = headings[i]
            hash_in_schools_assessment_by_levels[:count] = cells[i + 1]
            hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

            if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
              @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
              # p hash_in_schools_assessment_by_levels
            end
          end
        end

        cells = xlsx.sheet(@sheets[sheet]).row(19)
        hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])
        if cells [1] != nil
          (0..3).each do |i|
            if cells [i + 1] != nil
              hash_in_schools_assessment_by_levels[:level] = headings[i]
              hash_in_schools_assessment_by_levels[:count] = cells[i + 1]
              hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

              if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                # p hash_in_schools_assessment_by_levels
              end
            end
          end
        end
      end

    elsif file_name.include?('-biology-final-corporation.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics_row = 4
        if file_name == 'ilearn-2022-biology-final-corporation.xlsx'
          demographics_row = 4
        end
        if file_name == 'ilearn-2021-biology-final-corporation.xlsx' or file_name == 'ilearn-2019-biology-final-corporation.xlsx'
          demographics_row = 5
        end

        demographics = xlsx.sheet(@sheets[sheet]).row(demographics_row).compact

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:demographic] = demographics[demographic]
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'ILEARN'

          sub_and_gr = @sheets[sheet].scan(/\b[\w+&.]+\b/)
          hash_in_schools_assessment[:subject] = sub_and_gr[0]
          hash_in_schools_assessment[:group] = sub_and_gr[1..].join(' ')

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ilearn-2022-biology-final-corporation.xlsx' then start_row = 6 end
          if file_name == 'ilearn-2021-biology-final-corporation.xlsx' or file_name == 'ilearn-2019-biology-final-corporation.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []

            unless @sheets[sheet].include?('ELA & Math')
              get_range(start = 7, index = demographic, quantity = 3, space = 4).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              [3 * (demographic + 1), 3 * (demographic + 1) + 1, 3 * (demographic + 1) + 2].each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
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

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 5
            if file_name == 'ilearn-2022-biology-final-corporation.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-biology-final-corporation.xlsx' or file_name == 'ilearn-2019-biology-final-corporation.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[2..5].map { |name| name.gsub("\n", " ").gsub(sub_and_gr[0], "").strip }
            unless @sheets[sheet].include?('ELA & Math')
              cells = xlsx.sheet(@sheets[sheet]).row(row_number)

              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..3).each do |i|
                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (demographic * 7) + 2]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
                #
                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  # p hash_in_schools_assessment_by_levels
                end
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    elsif file_name.include?('-biology-final-school.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length-1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics_row = 4
        if file_name == 'ilearn-2022-biology-final-school.xlsx'  then demographics_row = 4 end
        if file_name == 'ilearn-2021-biology-final-school.xlsx' or file_name == 'ilearn-2019-biology-final-school.xlsx'  then demographics_row = 5 end

        demographics = xlsx.sheet(@sheets[sheet]).row(demographics_row).compact

        hash_in_schools_assessment[:school_year] = get_year(file_name)
        hash_in_schools_assessment[:exam_name] = 'ILEARN'

        sub_and_gr = @sheets[sheet].scan(/\b[\w+&.]+\b/)
        hash_in_schools_assessment[:subject] = sub_and_gr[0]
        hash_in_schools_assessment[:group] = sub_and_gr[1..].join(' ')

        if demographics.length == 0

          # Create hash for in_schools_assessment table

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ilearn-2022-biology-final-school.xlsx'  then start_row = 6 end
          if file_name == 'ilearn-2021-biology-final-school.xlsx' or file_name == 'ilearn-2019-biology-final-school.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

            row_data = []

            get_range(start = 9, index = 0, quantity = 3, space = 4).each do |col|
              row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 5
            if file_name == 'ilearn-2022-biology-final-school.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-biology-final-school.xlsx' or file_name == 'ilearn-2019-biology-final-school.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[4..7].map { |name| name.gsub("\n", " ").gsub(sub_and_gr[0], "").strip }

            cells = xlsx.sheet(@sheets[sheet]).row(row_number)

            hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

            (0..3).each do |i|
              hash_in_schools_assessment_by_levels[:level] = headings[i]
              hash_in_schools_assessment_by_levels[:count] = cells[i + (demographics.length * 7) + 4]
              hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

              if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                # p hash_in_schools_assessment_by_levels
              end
            end
            # break
          end
        end

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:demographic] = demographics[demographic]

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'ilearn-2022-biology-final-school.xlsx'
            start_row = 6
          end
          if file_name == 'ilearn-2021-biology-final-school.xlsx' or file_name == 'ilearn-2019-biology-final-school.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

            row_data = []

            get_range(start = 9, index = demographic, quantity = 3, space = 4).each do |col|
              row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
            #
            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 5
            if file_name == 'ilearn-2022-biology-final-school.xlsx'
              headings_row = 5
            end
            if file_name == 'ilearn-2021-biology-final-school.xlsx' or file_name == 'ilearn-2019-biology-final-school.xlsx'
              headings_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[4..7].map { |name| name.gsub("\n", " ").gsub(sub_and_gr[0], "").strip }

            cells = xlsx.sheet(@sheets[sheet]).row(row_number)

            hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

            (0..3).each do |i|
              hash_in_schools_assessment_by_levels[:level] = headings[i]
              hash_in_schools_assessment_by_levels[:count] = cells[i + (demographic * 7) + 4]
              hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
              #
              if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                # p hash_in_schools_assessment_by_levels
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
            end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
        end

    elsif file_name.include?('-us-government-final-statewide-summary-disaggregated.xlsx')

      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        sub_and_gr = @sheets[sheet].scan(/\b[\w+&.]+\b/)

        hash_in_schools_assessment[:demographic] = 'Student Demographic'
        hash_in_schools_assessment[:number_of_students] = "Total\nProficient"
        hash_in_schools_assessment[:number_tested] = "Total\nTested"
        hash_in_schools_assessment[:rate_percent] = "Proficient \n%"

        arr_md5_hash = []

        # Create hash for in_schools_assessment table
        xlsx.sheet(@sheets[sheet]).each(hash_in_schools_assessment) do |hash|

          hash[:school_year] = get_year(file_name)
          hash[:exam_name] = 'ILEARN'
          hash[:subject] = sub_and_gr[0..1].join(' ')
          hash[:group] = sub_and_gr[2..].join(' ')
          hash[:data_source_url] = @domain + file_name

          if hash[:demographic] == nil
            break
          else
            if hash[:demographic] != "Student Demographic"
              if hash[:rate_percent].is_a?(Float)
                hash[:rate_percent] = (hash[:rate_percent] * 100).round(1)
              end

              hash[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash)
              arr_md5_hash.push(hash[:md5_hash])

              if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
                @keeper.save_on_in_schools_assessment(hash)
                # puts hash.inspect
              end
            end
          end
        end

        start_row = 19

        hash_in_schools_assessment = {
          # school_year: '',
          # exam_name: 'ILEARN',
          # grade: '',
          # subject: '',
          # group: '',
          # demographic: '',
          # number_of_students: '',
          # number_tested: '',
          # rate_percent: ''
        }

        (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
          cells = xlsx.sheet(@sheets[sheet]).row(row_number)
          if cells[1].nil?
            break
          else
            hash_in_schools_assessment = {
              demographic: cells[0],
              school_year: get_year(file_name),
              exam_name: 'ILEARN',
              subject: sub_and_gr[0..1].join(' '),
              group: sub_and_gr[2..].join(' '),
              number_of_students: cells[3],
              number_tested: cells[4],
              rate_percent: if cells[5].is_a?(Float) then
                              (cells[5] * 100).round(1)
                            end,
              data_source_url: @domain + file_name,
            }
          end
          hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

          if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
            @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
            # p hash_in_schools_assessment
          end
        end

        # Create hash for in_schools_assessment_by_levels table
        headings = xlsx.sheet(@sheets[sheet]).row(1)[1..2].map { |name| name.gsub("\n", " ").gsub(sub_and_gr[0], "").strip }

        (0..14).each do |row_number|
          cells = xlsx.sheet(@sheets[sheet]).row(row_number + 2)
          hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: arr_md5_hash[row_number])

          (0..1).each do |i|
            hash_in_schools_assessment_by_levels[:level] = headings[i]
            hash_in_schools_assessment_by_levels[:count] = cells[i + 1]
            hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

            if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
              @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
              # p hash_in_schools_assessment_by_levels
            end
          end
        end

        cells = xlsx.sheet(@sheets[sheet]).row(19)
        if cells [1] != nil
          (0..1).each do |i|
            if cells [i + 1] != nil
              hash_in_schools_assessment_by_levels[:level] = headings[i]
              hash_in_schools_assessment_by_levels[:count] = cells[i + 1]
              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])
              hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

              if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                # p hash_in_schools_assessment_by_levels
              end
            end
          end
        end
      end

    elsif file_name.include?('-us-government-final-corp.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics_row = 5
        if file_name == 'ilearn-2022-us-government-final-corp.xlsx' or file_name == 'ilearn-2021-us-government-final-corp.xlsx'
          demographics_row = 5
        end
        if file_name == 'ilearn-2019-us-government-final-corp.xlsx'
          demographics_row = 6
        end

        demographics = xlsx.sheet(@sheets[sheet]).row(demographics_row).compact

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:demographic] = demographics[demographic]
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'ILEARN'

          sub_and_gr = @sheets[sheet].scan(/\b[\w+&.]+\b/)
          hash_in_schools_assessment[:subject] = sub_and_gr[0..1].join(' ')
          hash_in_schools_assessment[:group] = sub_and_gr[2..].join(' ')

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 7
          if file_name == 'ilearn-2022-us-government-final-corp.xlsx' or file_name == 'ilearn-2021-us-government-final-corp.xlsx'
            start_row = 7
          end
          if file_name == 'ilearn-2019-us-government-final-corp.xlsx'
            start_row = 8
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []

            get_range(start = 5, index = demographic, quantity = 3, space = 2).each do |col|
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

            # Create hash for in_schools_assessment_by_levels table

            headings_row = 6
            if file_name == 'ilearn-2022-us-government-final-corp.xlsx' or file_name == 'ilearn-2021-us-government-final-corp.xlsx'
              headings_row = 6
            end
            if file_name == 'ilearn-2019-us-government-final-corp.xlsx'
              headings_row = 7
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[2..3].map { |name| name.gsub("\n", " ").split(' ')[-2..].join(' ') }

            cells = xlsx.sheet(@sheets[sheet]).row(row_number)

            hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

            (0..1).each do |i|
              hash_in_schools_assessment_by_levels[:level] = headings[i]
              hash_in_schools_assessment_by_levels[:count] = cells[i + (demographic * 5) + 2]
              hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

              if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                # p hash_in_schools_assessment_by_levels
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    elsif file_name.include?('-us-government-final-school.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        demographics_row = 5
        if file_name == 'ilearn-2022-us-government-final-school.xlsx' or file_name == 'ilearn-2021-us-government-final-school.xlsx'
          demographics_row = 5
        end
        if file_name == 'ilearn-2019-us-government-final-school.xlsx'
          demographics_row = 6
        end

        demographics = xlsx.sheet(@sheets[sheet]).row(demographics_row).compact

        if demographics.length == 0 then
          demographics.push(nil)
        end

        # Create hash for in_schools_assessment table
        hash_in_schools_assessment[:school_year] = get_year(file_name)
        hash_in_schools_assessment[:exam_name] = 'ILEARN'

        sub_and_gr = @sheets[sheet].scan(/\b[\w+&.]+\b/)
        hash_in_schools_assessment[:subject] = sub_and_gr[0]
        hash_in_schools_assessment[:group] = sub_and_gr[1..].join(' ') == '' ? nil : sub_and_gr[1..].join(' ')

        parser_head = [:number_of_students, :number_tested, :rate_percent]

        start_row = 7
        if file_name == 'ilearn-2022-us-government-final-school.xlsx'
          start_row = 7
        end
        if file_name == 'ilearn-2021-us-government-final-school.xlsx' or file_name == 'ilearn-2019-us-government-final-school.xlsx'
          start_row = 8
        end

        (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

          row_data = []

          get_range(start = 7, index = demographic, quantity = 3, space = 2).each do |col|
            row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
          end

          result = parser_head.zip(row_data).to_h

          hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

          if hash_in_schools_assessment[:rate_percent].is_a?(Float)
            hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
          end

          hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
          hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

          if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
            @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
            # p hash_in_schools_assessment
          end

          # Create hash for in_schools_assessment_by_levels table

          if file_name == 'ilearn-2022-us-government-final-school.xlsx'
            headings_row = 6
          end
          if file_name == 'ilearn-2021-us-government-final-school.xlsx' or file_name == 'ilearn-2019-us-government-final-school.xlsx'
            headings_row = 7
          end

          headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[4..5].map { |name| name.gsub("\n", " ").split(' ')[-2..].join(' ') }

          cells = xlsx.sheet(@sheets[sheet]).row(row_number)
          # (0..1).each { |i|
          #   hash_in_schools_assessment_by_levels[:level] = headings[i]
          #   hash_in_schools_assessment_by_levels[:count] = cells[i + (0 * 5) + 4]
          #   hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
          #
          #   if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
          #     @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
          #     # p hash_in_schools_assessment_by_levels
          #   end
          # }
        end

        (0..demographics.length - 1).each do |demographic|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:demographic] = demographics[demographic]
          hash_in_schools_assessment[:exam_name] = 'ILEARN'
          hash_in_schools_assessment[:school_year] = get_year(file_name)

          sub_and_gr = @sheets[sheet].scan(/\b[\w+&.]+\b/)
          hash_in_schools_assessment[:subject] = sub_and_gr[0..1].join(' ')
          hash_in_schools_assessment[:group] = sub_and_gr[2..].join(' ')

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 7
          if file_name == 'ilearn-2022-us-government-final-school.xlsx' or file_name == 'ilearn-2021-us-government-final-school.xlsx'
            start_row = 7
          end
          if file_name == 'ilearn-2019-us-government-final-school.xlsx'
            start_row = 8
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []

            get_range(start = 7, index = demographic, quantity = 3, space = 2).each do |col|
              row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)

            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)

            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end

            # Create hash for in_schools_assessment_by_levels table
            headings_row = 6
            if file_name == 'ilearn-2022-us-government-final-school.xlsx' or file_name == 'ilearn-2021-us-government-final-school.xlsx'
              headings_row = 6
            end
            if file_name == 'ilearn-2019-us-government-final-school.xlsx'
              headings_row = 7
            end

            headings = xlsx.sheet(@sheets[sheet]).row(headings_row)[4..5].map { |name| name.gsub("\n", " ").split(' ')[-2..].join(' ') }

            hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

            cells = xlsx.sheet(@sheets[sheet]).row(row_number)
            (0..1).each do |i|
              hash_in_schools_assessment_by_levels[:level] = headings[i]
              hash_in_schools_assessment_by_levels[:count] = cells[i + (demographic * 5) + 4]

              hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)

              if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                # p hash_in_schools_assessment_by_levels
              end
            end
            # If ON BREAK -> One Meals if OFF BREAK -> One Column
            # break
          end
          # If ON BREAK -> One Column if OFF BREAK -> All sheet
          # break
        end
        # If ON BREAK -> All sheet if OFF BREAK -> All file
        # break
      end

    end
  end
end