
def parser_sat(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_schools_sat => MD5Hash.new(columns:%i[general_id grade subject demographic below_benchmark approaching_benchmark at_benchmark total_tested benchmark_percent school_year data_source_url])
  }

  arr_names_files.each do |file_name|

    path = "#{storehouse}store/sat/#{file_name}"
    xlsx = Roo::Spreadsheet.open(path)

    @sheets = xlsx.sheets

    logger.info "*************** Starting parser of #{file_name} ***************"

    hash_in_schools_sat = {
      # school_year: '',
      # grade: 'Grade 11',
      # subject: '',
      # demographic: '',
      # below_benchmark: '',
      # approaching_benchmark: '',
      # at_benchmark: '',
      # total_tested: '',
      # benchmark_percent: ''
    }

    if file_name == 'sat-2022-grade11-final-statewide-summary-v2.xlsx'

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        hash_in_schools_sat = {
          # school_year: '',
          # grade: 'Grade 11',
          # subject: '',
          # demographic: '',
          # below_benchmark: '',
          # approaching_benchmark: '',
          # at_benchmark: '',
          # total_tested: '',
          # benchmark_percent: ''
        }

        if @sheets[sheet] != 'Both'
          hash_in_schools_sat[:demographic] = 'Student Demographic'
          hash_in_schools_sat[:below_benchmark] = "#{@sheets[sheet]}\nBelow Benchmark"
          hash_in_schools_sat[:approaching_benchmark] = "#{@sheets[sheet]} \nApproaching Benchmark"
          hash_in_schools_sat[:at_benchmark] = "#{@sheets[sheet]} \nAt\nBenchmark"
          hash_in_schools_sat[:total_tested] = "#{@sheets[sheet]}\nTotal\nTested"
          hash_in_schools_sat[:benchmark_percent] = "#{@sheets[sheet]}\nBenchmark \n%"
        else
          hash_in_schools_sat[:demographic] = 'Student Demographic'
          hash_in_schools_sat[:at_benchmark] = "#{@sheets[sheet]} EBRW & Math\nAt\nBenchmark"
          hash_in_schools_sat[:total_tested] = "#{@sheets[sheet]} EBRW & Math\nTotal\nTested"
          hash_in_schools_sat[:benchmark_percent] = "#{@sheets[sheet]} EBRW & Math\nBenchmark \n%"
        end

        # Create hash for in_schools_sat table
        xlsx.sheet(@sheets[sheet]).each(hash_in_schools_sat) do |hash|

          hash[:school_year] = get_year(file_name)
          hash[:subject] = @sheets[sheet]
          hash[:grade] = 'Grade 11'

          if hash[:demographic] == nil or hash[:demographic] == 'All Students'
            break
          else
            if hash[:demographic] != "Student Demographic"

              if hash[:benchmark_percent].is_a?(Float)
                hash[:benchmark_percent] = (hash[:benchmark_percent] * 100).round(1)
              end

              hash[:data_source_url] = @domain + file_name
              hash[:md5_hash] = @md5_cash_maker[:in_schools_sat].generate(hash)
              if @keeper.existed_data_in_schools_sat(hash).nil?
                @keeper.save_on_in_schools_sat(hash)
                # puts hash.inspect
              end
            end
          end
        end
      end

    elsif file_name == 'sat-2022-grade11-final-corporation-v2.xlsx'

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        if !'Demographics'.in? @sheets[sheet]
          subject = xlsx.sheet(@sheets[sheet]).row(4).compact
        else
          demographics = xlsx.sheet(@sheets[sheet]).row(4).compact
        end

        if !'Demographics'.in? @sheets[sheet]

          (0..subject.length - 1).each do |grade|

            # Create hash for in_schools_sat table

            parser_head = [:below_benchmark, :approaching_benchmark, :at_benchmark, :total_tested, :benchmark_percent]
            parser_head_for_both = [:at_benchmark, :total_tested, :benchmark_percent]

            (6..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

              hash_in_schools_sat = {
                # school_year: '',
                # grade: 'Grade 11',
                # subject: '',
                # demographic: '',
                # below_benchmark: '',
                # approaching_benchmark: '',
                # at_benchmark: '',
                # total_tested: '',
                # benchmark_percent: ''
              }
              row_data = []

              if @sheets[sheet] != 'Both'
                [3, 4, 5, 6, 7].each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end
                result = parser_head.zip(row_data).to_h
              else
                [3, 4, 5].each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end

                result = parser_head_for_both.zip(row_data).to_h
              end

              # result = parser_head.zip(row_data).to_h

              hash_in_schools_sat = hash_in_schools_sat.merge(result)

              hash_in_schools_sat[:school_year] = get_year(file_name)
              hash_in_schools_sat[:grade] = 'Grade 11'
              hash_in_schools_sat[:subject] = @sheets[sheet] == 'Both' ? 'Both EBRW & Math' : @sheets[sheet]
              hash_in_schools_sat[:data_source_url] = @domain + file_name

              if hash_in_schools_sat[:benchmark_percent].is_a?(Float)
                hash_in_schools_sat[:benchmark_percent] = (hash_in_schools_sat[:benchmark_percent] * 100).round(1)
              end

              hash_in_schools_sat[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 1))
              hash_in_schools_sat[:md5_hash] = @md5_cash_maker[:in_schools_sat].generate(hash_in_schools_sat)
              if @keeper.existed_data_in_schools_sat(hash_in_schools_sat).nil?
                @keeper.save_on_in_schools_sat(hash_in_schools_sat)
                # p hash_in_schools_sat
              end
              # break
            end
            # break
          end
          # break

        else

          (0..demographics.length - 1).each do |demographic|

            # Create hash for in_schools_sat table
            hash_in_schools_sat = {
              # school_year: '',
              # grade: 'Grade 11',
              # subject: '',
              # demographic: '',
              # below_benchmark: '',
              # approaching_benchmark: '',
              # at_benchmark: '',
              # total_tested: '',
              # benchmark_percent: ''
            }

            parser_head = [:below_benchmark, :approaching_benchmark, :at_benchmark, :total_tested, :benchmark_percent]
            parser_head_for_both = [:at_benchmark, :total_tested, :benchmark_percent]

            (6..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
              row_data = []

              if @sheets[sheet] != 'Both Demographics'
                (3 + (demographic * 5)..(3 + (demographic * 5) + 4)).each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end
                result = parser_head.zip(row_data).to_h
              else
                (3 + (demographic * 3)..(3 + (demographic * 3) + 2)).each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end
                result = parser_head_for_both.zip(row_data).to_h
              end

              # result = parser_head.zip(row_data).to_h

              hash_in_schools_sat = hash_in_schools_sat.merge(result)

              hash_in_schools_sat[:school_year] = get_year(file_name)
              hash_in_schools_sat[:grade] = 'Grade 11'
              hash_in_schools_sat[:subject] = @sheets[sheet]
              hash_in_schools_sat[:demographic] = demographics[demographic]
              hash_in_schools_sat[:data_source_url] = @domain + file_name

              if hash_in_schools_sat[:benchmark_percent].is_a?(Float)
                hash_in_schools_sat[:benchmark_percent] = (hash_in_schools_sat[:benchmark_percent] * 100).round(1)
              end

              hash_in_schools_sat[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 1))
              hash_in_schools_sat[:md5_hash] = @md5_cash_maker[:in_schools_sat].generate(hash_in_schools_sat)
              if @keeper.existed_data_in_schools_sat(hash_in_schools_sat).nil?
                @keeper.save_on_in_schools_sat(hash_in_schools_sat)
                # p hash_in_schools_sat
              end

              # break
            end
            # break
          end
          # break
        end
      end

    elsif file_name == 'sat-2022-grade11-final-school-v2.xlsx'

      (0..@sheets.length - 1).each do |sheet|

        logger.info "*************** Starting parser of #{@sheets[sheet]} ***************"

        if !'Demographics'.in? @sheets[sheet]
          subject = xlsx.sheet(@sheets[sheet]).row(4).compact
        else
          demographics = xlsx.sheet(@sheets[sheet]).row(4).compact
        end

        if !'Demographics'.in? @sheets[sheet]

          (0..subject.length - 1).each do |grade|

            # Create hash for in_schools_sat table

            parser_head = [:below_benchmark, :approaching_benchmark, :at_benchmark, :total_tested, :benchmark_percent]
            parser_head_for_both = [:at_benchmark, :total_tested, :benchmark_percent]

            (6..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|

              hash_in_schools_sat = {
                # school_year: '',
                # grade: 'Grade 11',
                # subject: '',
                # demographic: '',
                # below_benchmark: '',
                # approaching_benchmark: '',
                # at_benchmark: '',
                # total_tested: '',
                # benchmark_percent: ''
              }
              row_data = []

              if @sheets[sheet] != 'Both'
                [5, 6, 7, 8, 9].each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end
                result = parser_head.zip(row_data).to_h
              else
                [5, 6, 7].each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end

                result = parser_head_for_both.zip(row_data).to_h
              end

              # result = parser_head.zip(row_data).to_h

              hash_in_schools_sat = hash_in_schools_sat.merge(result)

              hash_in_schools_sat[:school_year] = get_year(file_name)
              hash_in_schools_sat[:grade] = 'Grade 11'
              hash_in_schools_sat[:subject] = @sheets[sheet] == 'Both' ? 'Both EBRW & Math' : @sheets[sheet]
              hash_in_schools_sat[:data_source_url] = @domain + file_name

              if hash_in_schools_sat[:benchmark_percent].is_a?(Float)
                hash_in_schools_sat[:benchmark_percent] = (hash_in_schools_sat[:benchmark_percent] * 100).round(1)
              end

              hash_in_schools_sat[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
              hash_in_schools_sat[:md5_hash] = @md5_cash_maker[:in_schools_sat].generate(hash_in_schools_sat)
              if @keeper.existed_data_in_schools_sat(hash_in_schools_sat).nil?
                @keeper.save_on_in_schools_sat(hash_in_schools_sat)
                # p hash_in_schools_sat
              end

              # break
            end
            # break
          end
          # break

        else

          (0..demographics.length - 1).each do |demographic|

            # Create hash for in_schools_sat table
            hash_in_schools_sat = {
              # school_year: '',
              # grade: 'Grade 11',
              # subject: '',
              # demographic: '',
              # below_benchmark: '',
              # approaching_benchmark: '',
              # at_benchmark: '',
              # total_tested: '',
              # benchmark_percent: ''
            }

            parser_head = [:below_benchmark, :approaching_benchmark, :at_benchmark, :total_tested, :benchmark_percent]
            parser_head_for_both = [:at_benchmark, :total_tested, :benchmark_percent]

            (6..xlsx.sheet(@sheets[sheet]).last_row).each do |row_number|
              row_data = []

              if @sheets[sheet] != 'Both Demographics'
                (5 + (demographic * 5)..(5 + (demographic * 5) + 4)).each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end
                result = parser_head.zip(row_data).to_h
              else
                (5 + (demographic * 3)..(5 + (demographic * 3) + 2)).each do |col|
                  row_data << xlsx.sheet(@sheets[sheet]).cell(row_number, col)
                end
                result = parser_head_for_both.zip(row_data).to_h
              end

              # result = parser_head.zip(row_data).to_h

              hash_in_schools_sat = hash_in_schools_sat.merge(result)

              hash_in_schools_sat[:school_year] = get_year(file_name)
              hash_in_schools_sat[:grade] = 'Grade 11'
              hash_in_schools_sat[:subject] = @sheets[sheet]
              hash_in_schools_sat[:demographic] = demographics[demographic]
              hash_in_schools_sat[:data_source_url] = @domain + file_name

              if hash_in_schools_sat[:benchmark_percent].is_a?(Float)
                hash_in_schools_sat[:benchmark_percent] = (hash_in_schools_sat[:benchmark_percent] * 100).round(1)
              end

              hash_in_schools_sat[:general_id] = @keeper.get_global_id(xlsx.sheet(@sheets[sheet]).cell(row_number, 3))
              hash_in_schools_sat[:md5_hash] = @md5_cash_maker[:in_schools_sat].generate(hash_in_schools_sat)
              if @keeper.existed_data_in_schools_sat(hash_in_schools_sat).nil?
                @keeper.save_on_in_schools_sat(hash_in_schools_sat)
                # p hash_in_schools_sat
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