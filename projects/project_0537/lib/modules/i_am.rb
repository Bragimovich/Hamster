
def parser_i_am_alternate(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_schools_assessment => MD5Hash.new(columns:%i[general_id exam_name grade subject group demographic number_of_students number_tested rate_percent data_source_url]),
    :in_schools_assessment_by_levels => MD5Hash.new(columns:%i[assessment_id level count]),
  }

  arr_names_files.each do |file_name|

    logger.info "*************** Starting parser of #{file_name} ***************"

    path = "#{storehouse}store/i_am/#{file_name}"
    xlsx = Roo::Spreadsheet.open(path)
    @sheets = xlsx.sheets

    hash_in_schools_assessment = {
      # school_year: '',
      # exam_name: 'I AM',
      # grade: '',
      # subject: '',
      # group: '',
      # demographic: '',
      # number_of_students: '',
      # number_tested: '',
      # rate_percent: ''
    }
    hash_in_schools_assessment_by_levels = {
      # level: '',
      # count: '',
    }

    if file_name.include?('-final-statewide-summary.xlsx')

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        hash_in_schools_assessment[:demographic] = 'Student Demographic'
        hash_in_schools_assessment[:number_of_students] = "Total\nProficient"
        hash_in_schools_assessment[:number_tested] = "Total\nTested"
        hash_in_schools_assessment[:rate_percent] = "Proficient \n%"

        arr_md5_hash = []

        # Create hash for in_schools_assessment table
        xlsx.sheet(@sheets[sheet]).each(hash_in_schools_assessment) do |hash|

          hash[:school_year] = get_year(file_name)
          hash[:exam_name] = 'I AM'
          hash[:subject] = @sheets[sheet]

          if hash[:demographic] == nil
            break
          else
            if hash[:demographic] != "Student Demographic"

              if hash[:rate_percent].is_a?(Float)
                hash[:rate_percent] = (hash[:rate_percent] * 100).round(1)
              end

              hash[:data_source_url] = @domain + file_name
              hash[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash)

              arr_md5_hash.push(hash[:md5_hash])

              if @keeper.existed_data_in_schools_assessment(hash).nil?
                @keeper.save_on_in_schools_assessment(hash)
                # p hash
              end
            end
          end
        end

        (13..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
          hash_in_schools_assessment = {
          }

          cells = xlsx.sheet(@sheets[sheet]).row(row_number)

          if cells[1].nil?
            break
          else
            if @sheets[sheet] != 'Both Eng and Math'
              hash_in_schools_assessment = {
                school_year: get_year(file_name),
                exam_name: 'I AM',
                grade: nil,
                subject: @sheets[sheet],
                data_source_url: @domain + file_name,
                # group: '',
                # demographic: '',
                number_of_students: cells[4],
                number_tested: cells[5],
                rate_percent: if cells[6].is_a?(Float) then (cells[6] * 100).round(1) end
              }
            else
              hash_in_schools_assessment = {
                school_year: get_year(file_name),
                exam_name: 'I AM',
                grade: nil,
                subject: @sheets[sheet],
                data_source_url: @domain + file_name,
                # group: '',
                # demographic: '',
                number_of_students: cells[1],
                number_tested: cells[2],
                rate_percent: if cells[3].is_a?(Float) then (cells[3] * 100).round(1) end
              }
            end
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
            arr_md5_hash.push(hash_in_schools_assessment[:md5_hash])
            if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
              @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
              # p hash_in_schools_assessment
            end
          end
        end

        # Create hash for in_schools_assessment_by_levels table
        headings = xlsx.sheet(@sheets[sheet]).row(1)[1..3].map { |name| name.gsub("\n", " ").gsub(@sheets[sheet], "").strip }

        if @sheets[sheet] != 'Both Eng and Math'
          (2..10).each do |row_number|
            cells = xlsx.sheet(@sheets[sheet]).row(row_number)

            hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name
            hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: arr_md5_hash[row_number - 2])

            (0..2).each do |i|

              hash_in_schools_assessment_by_levels[:level] = headings[i]
              hash_in_schools_assessment_by_levels[:count] = cells[i + 1]

              if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
                @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                # p hash_in_schools_assessment_by_levels
              end
            end
          end

          (13..14).each do |row_number|
            cells = xlsx.sheet(@sheets[sheet]).row(row_number)

            hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name
            hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: arr_md5_hash.last)

            if cells [1] != nil
              (0..2).each do |i|
                if cells [i + 1] != nil
                  hash_in_schools_assessment_by_levels[:level] = headings[i]
                  hash_in_schools_assessment_by_levels[:count] = cells[i + 1]

                  if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                    hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
                    @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                    # p hash_in_schools_assessment_by_levels
                  end
                end
              end
            end
          end
        end
        # break
      end

    elsif file_name.include?('-final-corporation.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        sub_row = 4
        if file_name == 'i-am-2019-final-corporation.xlsx'
          sub_row = 5
        end
        subjects = xlsx.sheet(@sheets[sheet]).row(sub_row).compact.map { |sub| sub.gsub('I AM ', '') }
        if subjects.length == 0
          subjects << ('Math and English')
        end

        (0..subjects.length - 1).each do |sub|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'I AM'
          hash_in_schools_assessment[:subject] = subjects[sub]

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'i-am-2019-final-corporation.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []
            if @sheets[sheet] != 'I AM Math and English'
              get_range(start = 6, index = sub, quantity = 3, space = 3).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              get_range(start = 3, index = sub, quantity = 3, space = 0).each do |col|
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
            heading_row = 5
            if file_name == 'i-am-2019-final-corporation.xlsx'
              heading_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(heading_row)[2..4].map { |name| name.gsub("\n", " ").gsub(@sheets[sheet], "").strip }

            if @sheets[sheet] != 'I AM Math and English'
              cells = xlsx.sheet(@sheets[sheet]).row(row_number)
              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..2).each do |i|
                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (sub * 7) + 2]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  # p hash_in_schools_assessment_by_levels
                end
              end
            end
            # break
          end
          # break
        end
        # break
      end

    elsif file_name.include?('-final-school.xlsx')

      hash_in_schools_assessment[:data_source_url] = @domain + file_name
      hash_in_schools_assessment_by_levels[:data_source_url] = @domain + file_name

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        sub_row = 4
        if file_name == 'i-am-2019-final-school.xlsx'
          sub_row = 5
        end
        subjects = xlsx.sheet(@sheets[sheet]).row(sub_row).compact.map { |sub| sub.gsub('I AM ', '') }
        if subjects.length == 0
          subjects << ('Math and English')
        end

        (0..subjects.length - 1).each do |sub|

          # Create hash for in_schools_assessment table
          hash_in_schools_assessment[:school_year] = get_year(file_name)
          hash_in_schools_assessment[:exam_name] = 'I AM'
          hash_in_schools_assessment[:subject] = subjects[sub]

          parser_head = [:number_of_students, :number_tested, :rate_percent]

          start_row = 6
          if file_name == 'i-am-2019-final-school.xlsx'
            start_row = 7
          end

          (start_row..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
            row_data = []
            if !@sheets[sheet].include?('Math and Eng')
              get_range(start = 8, index = sub, quantity = 3, space = 3).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            else
              get_range(start = 5, index = sub, quantity = 3, space = 3).each do |col|
                row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
              end
            end

            result = parser_head.zip(row_data).to_h

            hash_in_schools_assessment = hash_in_schools_assessment.merge(result)
            if hash_in_schools_assessment[:rate_percent].is_a?(Float)
              hash_in_schools_assessment[:rate_percent] = (hash_in_schools_assessment[:rate_percent] * 100).round(1)
            end

            hash_in_schools_assessment[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
            # #
            hash_in_schools_assessment[:md5_hash] = @md5_cash_maker[:in_schools_assessment].generate(hash_in_schools_assessment)
            # if @keeper.existed_data_in_schools_assessment(hash_in_schools_assessment).nil?
            @keeper.save_on_in_schools_assessment(hash_in_schools_assessment)
            # p hash_in_schools_assessment
            # end

            # Create hash for in_schools_assessment_by_levels table
            heading_row = 5
            if file_name == 'i-am-2019-final-school.xlsx'
              heading_row = 6
            end

            headings = xlsx.sheet(@sheets[sheet]).row(heading_row)[4..6].map { |name| name.gsub("\n", " ").gsub(@sheets[sheet], "").strip }

            unless @sheets[sheet].include?('Math and Eng')
              cells = xlsx.sheet(@sheets[sheet]).row(row_number)

              hash_in_schools_assessment_by_levels[:assessment_id] = @keeper.get_assessment_id(md5_hash: hash_in_schools_assessment[:md5_hash])

              (0..2).each do |i|
                hash_in_schools_assessment_by_levels[:level] = headings[i]
                hash_in_schools_assessment_by_levels[:count] = cells[i + (sub * 7) + 4]
                hash_in_schools_assessment_by_levels[:md5_hash] = @md5_cash_maker[:in_schools_assessment_by_levels].generate(hash_in_schools_assessment_by_levels)
                if @keeper.existed_data_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels).nil?
                  @keeper.save_on_in_schools_assessment_by_levels(hash_in_schools_assessment_by_levels)
                  # p hash_in_schools_assessment_by_levels
                end
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