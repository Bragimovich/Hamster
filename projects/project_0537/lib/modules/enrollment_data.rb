require_relative '../keeper'

def parser_enrollment_grade_info(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_enrollment_by_grade => MD5Hash.new(columns:%i[general_id school_year gender grade count]),
  }

  arr_names_files.each do |file_name|

    if file_name.include?('-enrollment-grade-gender-')

      logger.info "*************** Starting parser of #{file_name} ***************"

      path = "#{storehouse}store/enrollment/#{file_name}"

      xlsx = Roo::Spreadsheet.open(path)

      @sheets = xlsx.sheets

    if file_name.include?('corporation-enrollment-grade-gender-')

      (0..@sheets.length-1).each do |i|
        sheet = @sheets[i]

        hash_in_enrollment_by_grade = {
          # general_id: '',
          # school_year: '',
          # gender: '',
          # grade: '',
          # count: '',
        }

        logger.info "*************** Starting parser of #{sheet} ***************"


        grades = xlsx.sheet(@sheets[i]).row(1).split.map { |arr| if arr.join != '' then arr.join end }.compact
        gender = ['Female', 'Male']
        school_year = "#{sheet.to_i-1}-#{sheet.to_i}"

        # Create hash for in_enrollment_by_grade table
        (3..xlsx.sheet(@sheets[i]).last_row).each do |row_number|
          counts = xlsx.sheet(@sheets[i]).row(row_number)

          hash_in_enrollment_by_grade[:school_year] = school_year
          hash_in_enrollment_by_grade[:data_source_url] = @domain + file_name

          (0..grades.length * 2 - 1).each do |i|
            cell = i + 2
            if cell % 2 == 0
              hash_in_enrollment_by_grade[:gender] = gender[0]
              hash_in_enrollment_by_grade[:grade] = grades[i / 2]
            else
              hash_in_enrollment_by_grade[:gender] = gender[1]
            end
            hash_in_enrollment_by_grade[:count] = counts[cell]
            hash_in_enrollment_by_grade[:general_id] = @keeper.get_global_id(counts[0])

            if @keeper.existed_data_enrollment_by_grade_table(hash_in_enrollment_by_grade).nil?
              hash_in_enrollment_by_grade[:md5_hash] = @md5_cash_maker[:in_enrollment_by_grade].generate(hash_in_enrollment_by_grade)
              @keeper.save_on_in_enrollment_by_grade(hash_in_enrollment_by_grade)
              # puts hash_in_enrollment_by_grade
            end
            # break
            end
          # break
          end
        # break
        end

    else

      (0..@sheets.length - 1).each do |i|

        sheet = @sheets[i]

        hash_in_enrollment_by_grade = {
          # general_id: '',
          # school_year: '',
          # gender: '',
          # grade: '',
          # count: '',
        }

        logger.info "*************** Starting parser of #{sheet} ***************"

        grades = xlsx.sheet(@sheets[i]).row(1).split.map { |arr|
          if arr.join != ' ' and arr.join != '' then
            arr.join
          end }.compact
        gender = ['Female', 'Male']
        school_year = "#{sheet.to_i - 1}-#{sheet.to_i}"

        # Create hash for in_enrollment_by_grade table
        (3..xlsx.sheet(@sheets[i]).last_row).each do |row_number|

          counts = xlsx.sheet(@sheets[i]).row(row_number)

          hash_in_enrollment_by_grade[:school_year] = school_year
          hash_in_enrollment_by_grade[:data_source_url] = @domain + file_name

          (0..grades.length * 2 - 1).each do |i|
            cell = i + 4

            if cell % 2 == 0
              hash_in_enrollment_by_grade[:gender] = gender[0]
              hash_in_enrollment_by_grade[:grade] = grades[i / 2]
            else
              hash_in_enrollment_by_grade[:gender] = gender[1]
            end

            hash_in_enrollment_by_grade[:count] = counts[cell]
            hash_in_enrollment_by_grade[:general_id] = @keeper.get_global_id(counts[2])
            hash_in_enrollment_by_grade[:md5_hash] = @md5_cash_maker[:in_enrollment_by_grade].generate(hash_in_enrollment_by_grade)

            if @keeper.existed_data_enrollment_by_grade_table(hash_in_enrollment_by_grade).nil?
              @keeper.save_on_in_enrollment_by_grade(hash_in_enrollment_by_grade)
              # puts hash_in_enrollment_by_grade
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
end


def parser_enrollment_ethnicity(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_enrollment_by_ethnicity => MD5Hash.new(columns:%i[general_id school_year ethnicity count]),
    :in_enrollment_by_meal_status => MD5Hash.new(columns:%i[general_id school_year status count]),
  }

  arr_names_files.each do |file_name|

    if file_name.include?('-enrollment-ethnicity-and-free-reduced-price-meal-status-')

      path = "#{storehouse}store/enrollment/#{file_name}"

      xlsx = Roo::Spreadsheet.open(path)

      @sheets = xlsx.sheets

      (0..@sheets.length-1).each do |i|

        sheet = @sheets[i]

        hash_in_enrollment_by_ethnicity = {
          # general_id: '',
          # school_year: '',
          # ethnicity: '',
          # count: ''
        }
        hash_in_enrollment_by_meal_status = {
          # general_id: '',
          # school_year: '',
          # status: '',
          # count: ''
        }

        ethnicities = xlsx.sheet(@sheets[i]).row(1)[2..].map { |ethn| ethn.gsub("\n", " ")}[2..]

        school_year = "#{sheet.to_i-1}-#{sheet.to_i}"

        logger.info "*************** Starting parser of #{sheet} ***************"

        # Create hash for in_enrollment_by_ethnicity and in_enrollment_by_meal_status tables
        if file_name == 'corporation-enrollment-ethnicity-free-reduced-price-meal-status-2006-23.xlsx'

          (2..xlsx.sheet(@sheets[i]).last_row).each do |row_number|
            cells = xlsx.sheet(@sheets[i]).row(row_number)

            hash_in_enrollment_by_ethnicity[:general_id] = @keeper.get_global_id(cells[0])
            hash_in_enrollment_by_ethnicity[:school_year] = school_year
            hash_in_enrollment_by_ethnicity[:data_source_url] = @domain + file_name

            (0..ethnicities.length - 1).each do |i|
              cell = i + 2
              unless ethnicities[i].include?('Meals')
                hash_in_enrollment_by_ethnicity[:ethnicity] = ethnicities[i]
                hash_in_enrollment_by_ethnicity[:count] = cells[cell]
                hash_in_enrollment_by_ethnicity[:md5_hash] = @md5_cash_maker[:in_enrollment_by_ethnicity].generate(hash_in_enrollment_by_ethnicity)

                if @keeper.existed_data_enrollment_by_ethnicity(hash_in_enrollment_by_ethnicity).nil?
                  @keeper.save_on_in_enrollment_by_ethnicity(hash_in_enrollment_by_ethnicity)
                  #   puts hash_in_enrollment_by_ethnicity
                end
              else
                hash_in_enrollment_by_meal_status[:status] = ethnicities[i]
                hash_in_enrollment_by_meal_status[:count] = cells[cell]
                hash_in_enrollment_by_meal_status[:md5_hash] = @md5_cash_maker[:in_enrollment_by_meal_status].generate(hash_in_enrollment_by_meal_status)

                if @keeper.existed_data_enrollment_by_grade_table(hash_in_enrollment_by_grade).nil?
                  @keeper.save_on_in_enrollment_by_meal_status(hash_in_enrollment_by_meal_status)
                  # puts hash_in_enrollment_by_meal_status
                end
              end
            end
            # break
          end
        # break

        else
          (2..xlsx.sheet(@sheets[i]).last_row).each do |row_number|
            cells = xlsx.sheet(@sheets[i]).row(row_number)

            if cells[2].to_s.length == 2 then cells[2] = "00#{cells[2]}" end

            hash_in_enrollment_by_ethnicity[:general_id] = @keeper.get_global_id(cells[2])
            hash_in_enrollment_by_ethnicity[:school_year] = school_year
            hash_in_enrollment_by_ethnicity[:data_source_url] = @domain + file_name

            (0..ethnicities.length - 1).each do |i|
              cell = i + 4
              unless ethnicities[i].include?('Meals') or ethnicities[i].include?('meals')
                hash_in_enrollment_by_ethnicity[:ethnicity] = ethnicities[i]
                hash_in_enrollment_by_ethnicity[:count] = cells[cell]
                hash_in_enrollment_by_ethnicity[:md5_hash] = @md5_cash_maker[:in_enrollment_by_ethnicity].generate(hash_in_enrollment_by_ethnicity)

                if @keeper.existed_data_enrollment_by_ethnicity(hash_in_enrollment_by_ethnicity).nil?
                  @keeper.save_on_in_enrollment_by_ethnicity(hash_in_enrollment_by_ethnicity)
                # puts hash_in_enrollment_by_ethnicity
                end
              else
                hash_in_enrollment_by_meal_status[:status] = ethnicities[i]
                hash_in_enrollment_by_meal_status[:count] = cells[cell]
                hash_in_enrollment_by_meal_status[:md5_hash] = @md5_cash_maker[:in_enrollment_by_meal_status].generate(hash_in_enrollment_by_meal_status)

                if @keeper.existed_data_enrollment_by_meal_status(hash_in_enrollment_by_meal_status).nil?
                  @keeper.save_on_in_enrollment_by_meal_status(hash_in_enrollment_by_meal_status)
                # puts hash_in_enrollment_by_meal_status
                end
              end
            end
            end
        end
      end
    end
  end
end


def parser_enrollment_by_special_edu_and_ell(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_enrollment_by_special_edu_and_ell => MD5Hash.new(columns:%i[general_id school_year ell_count ell_percent special_edu_count special_edu_percent total_count]),
  }

  arr_names_files.each do |file_name|

    if file_name.include?('-enrollment-ell-special-education-2')

      path = "#{storehouse}store/enrollment/#{file_name}"

      xlsx = Roo::Spreadsheet.open(path)

      @sheets = xlsx.sheets

      (0..@sheets.length - 1).each do |i|
        sheet = @sheets[i]

        hash_in_enrollment_by_special_edu_and_ell = {
          general_id: 'Corp ID',
          # school_year: '',
          ell_count: 'ELL N',
          ell_percent: 'ELL %',
          special_edu_count: 'Special Education N',
          special_edu_percent: 'Special Education %',
          total_count: @sheets[i].to_i <= 2017 ? 'Total Enrollment' : 'TOTAL ENROLLMENT'
        }

        hash_in_enrollment_by_special_edu_and_ell_schl = {
          general_id: 'Schl ID',
          # school_year: '',
          ell_count: 'ELL N',
          ell_percent: 'ELL %',
          special_edu_count: 'Special Education N',
          special_edu_percent: 'Special Education %',
          total_count: 'Total Enrollment'
        }

        logger.info "*************** Starting parser of #{sheet} ***************"

        # Create hash for in_enrollment_by_special_edu_and_ell table
        if file_name == "corporation-enrollment-ell-special-education-2006-22-v2.xlsx"

          xlsx.sheet(@sheets[i]).each(hash_in_enrollment_by_special_edu_and_ell) do |hash|

            if hash[:ell_count] != "ELL N"

              hash[:general_id] = @keeper.get_global_id(hash[:general_id])
              hash[:school_year] = "#{sheet.to_i - 1}-#{sheet.to_i}"
              hash[:data_source_url] = @domain + file_name

              if hash[:ell_percent].is_a?(Float) then
                hash[:ell_percent] = (hash[:ell_percent] * 100).round(2)
              end
              if hash[:special_edu_percent].is_a?(Float) then
                hash[:special_edu_percent] = (hash[:special_edu_percent] * 100).round(2)
              end

              hash[:md5_hash] = @md5_cash_maker[:in_enrollment_by_special_edu_and_ell].generate(hash)

              if @keeper.existed_data_enrollment_by_special_edu_and_ell(hash).nil?
                @keeper.save_on_in_enrollment_by_special_edu_and_ell(hash)
                # puts hash.inspect
              end
              # break
            end
          end
          # break
        else
          xlsx.sheet(@sheets[i]).each(hash_in_enrollment_by_special_edu_and_ell_schl) do |hash|

            if hash[:ell_count] != "ELL N"

              hash[:general_id] = @keeper.get_global_id(hash[:general_id])
              hash[:school_year] = "#{sheet.to_i - 1}-#{sheet.to_i}"
              hash[:data_source_url] = @domain + file_name

              if hash[:ell_percent].is_a?(Float) then
                hash[:ell_percent] = (hash[:ell_percent] * 100).round(2)
              end
              if hash[:special_edu_percent].is_a?(Float) then
                hash[:special_edu_percent] = (hash[:special_edu_percent] * 100).round(2)
              end

              hash[:md5_hash] = @md5_cash_maker[:in_enrollment_by_special_edu_and_ell].generate(hash)

              if @keeper.existed_data_enrollment_by_special_edu_and_ell(hash).nil?
                @keeper.save_on_in_enrollment_by_special_edu_and_ell(hash)
                # puts hash.inspect
              end
              # break
            end
          end
          # break
        end
      end
    end
  end
end