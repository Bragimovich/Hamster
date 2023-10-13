require_relative '../transfer_cases/us_cases'
require_relative 'db_models'
require_relative '../transfer_cases/transfer_run_id'


module UnexpectedTasks
  module UsCourts
    module CaseManually
      class ManualToRawNew
        def self.run(**options)
          TransferManualToRaw1.new(**options) if options[:run]==1
          TransferManualToRaw2.new(**options)
        end
      end

      class TransferManualToRaw1
        def initialize(**options)
          #@court_staging_to_raw = court_staging_to_raw
          start
        end

        def start
          limit = 5
          page = 0

          run_id_info = TransferRunId.new(:info).run_id
          @run_id_party = TransferRunId.new(:party).run_id
          run_id_pdfs_on_aws = TransferRunId.new(:pdfs_on_aws).run_id

          md5_info_class = MD5Hash.new(columns:%w[court_id case_id case_name judge_name case_filed_date case_type])
          md5_pdfs_class = MD5Hash.new(columns:%w[court_id case_id source_type aws_link])


          loop do
            p page
            offset = limit*page

            manual_cases = CasesWithPdfFromCSV.where(done:1).limit(limit).offset(offset)
            manual_case_id = manual_cases.map{|row| row.case_id}
            existed_cases = UsCaseInfoCourts.where(case_id:manual_case_id).map {|row| row.case_id.strip}
            manual_cases.each do |row|
              break if row.court_name.nil?
              court_info = NewCourtsTable.where(court_name: row.court_name.strip).first
              if court_info.nil? and row.court_id.nil?
                p row.court_name
                next
              end
              next if  row.case_id.nil? or existed_cases.include?(row.case_id) #!court_info.old_court_id.nil?
              court_id =row.court_id || court_info.court_id
              if court_id.nil?
                p "WRONG: #{row.court_id}|#{court_info.court_id}"
                next
              end

              # case_id_str = case_id.str if !case_id.nil?
              info = {
                court_id: court_id, case_id: row.case_id.strip,

                case_name: row.case_name,
                case_filed_date: row.case_filed_date,
                case_description: row.lead_name,
                run_id: run_id_info, touched_run_id: run_id_info,
                created_by: 'Rylan Klatt'

              }
              info[:md5_hash] = md5_info_class.generate(info)
              p info
              pdfs_on_aws = {
                court_id: court_id, case_id: row.case_id.strip,
                source_type: 'info', aws_link: row.pdf,
                run_id: run_id_pdfs_on_aws, touched_run_id: run_id_pdfs_on_aws,
                created_by: 'Rylan Klatt'
              }

              pdfs_on_aws[:md5_hash] = md5_pdfs_class.generate(pdfs_on_aws)
              p pdfs_on_aws
              party = []

              party+=(get_plaintiff_people(row, info))
              party+=(get_defendant_people(row, info))
              party+=(get_lawyers(row, info))

              insert_to_db({info:info, party: party,pdfs_on_aws:pdfs_on_aws })
            end
            page=page+1

            break if manual_cases.to_a.length<limit
          end
        end

        def court_staging_to_raw
          courts = {}
          StagingCourts.all().each do |row|
            courts[row.id] = row.external_id
          end
          courts
        end

        def get_plaintiff_people(row, info)
          party = []
          md5_class = MD5Hash.new(columns: %w[court_id case_id party_name party_type is_lawyer
                                                 party_law_firm party_description])
          [1,2,3].each do |i|
            plaintiff_name = "Plaintiff #{i} Name"
            break if row[plaintiff_name].nil?

            party.push({
                         court_id: info[:court_id], case_id: info[:case_id],
                         party_name: row[plaintiff_name],
                         party_type: "Plaintiff", is_lawyer: 0,
                         party_law_firm: nil,
                         run_id: @run_id_party, touched_run_id: @run_id_party,
                         created_by: 'Rylan Klatt'
                       })
            plaintiff_type = "Plaintiff #{i} Type"
            if row[plaintiff_type]!='Person'
              #party[-1][:party_law_firm] = row[plaintiff_name]
              party[-1][:party_description] = row[plaintiff_type]
            else
              #party[-1][:party_law_firm] = nil
              party[-1][:party_description] = row["Plaintiff #{i} Sex (if Person)"]
            end
            party[-1][:md5_hash] = md5_class.generate(party[-1])
          end
          party
        end

        def get_defendant_people(row, info)
          party = []
          md5_class = MD5Hash.new(columns: %w[court_id case_id party_name party_type is_lawyer party_description])
          [1,2,3].each do |i|
            defendant_name = "Defendant #{i} name"
            break if row[defendant_name].nil?

            party.push({
                         court_id: info[:court_id], case_id: info[:case_id],
                         party_name: row[defendant_name],
                         party_type: "Defendant", is_lawyer: 0,
                         party_law_firm: nil,
                         run_id: @run_id_party, touched_run_id: @run_id_party,
                         created_by: 'Rylan Klatt'
                       })
            plaintiff_type = "Defendant #{i} Type"
            if row[plaintiff_type]!='Person'
              #party[-1][:party_law_firm] = row[defendant_name]
              party[-1][:party_description] = row[plaintiff_type]
            else
              #party[-1][:party_law_firm] = nil
              party[-1][:party_description] = row["Defendant #{i} Sex (if Person)"]
            end
            party[-1][:md5_hash] = md5_class.generate(party[-1])
          end
          party
        end

        def get_lawyers(row, info)
          party = []
          md5_class = MD5Hash.new(columns: %w[court_id case_id party_name party_type is_lawyer
                                                 party_law_firm party_description])
          ["Plaintiff", "Defendant"].each do |party_type|
            [1,2,3].each do |i|
              plaintiff_lawyer_name = "#{party_type} Lawyer Name #{i}"
              break if row[plaintiff_lawyer_name].nil?

              party.push({
                           court_id: info[:court_id], case_id: info[:case_id],
                           party_name: row[plaintiff_lawyer_name],
                           party_type: "#{party_type} Lawyer", is_lawyer: 1,
                           party_law_firm: row["#{party_type} Lawyer #{i} Law Firm"],
                           party_description: nil,
                           run_id: @run_id_party, touched_run_id: @run_id_party,
                           created_by: 'Rylan Klatt'
                         })
              party[-1][:md5_hash] = md5_class.generate(party[-1])
            end
          end
          party
        end

        def insert_to_db(data)
          UsCasePartyCourts.insert_all(data[:party]) if !data[:party].empty?
          UsCasePdfsOnAwsCourts.insert(data[:pdfs_on_aws]) if !data[:pdfs_on_aws].nil?
          UsCaseInfoCourts.insert(data[:info]) if !data[:info].nil?
        end


      end


      class TransferManualToRaw2
        def initialize(**options)
          #@court_staging_to_raw = court_staging_to_raw
          start
        end

        def start
          limit = 5
          page = 0

          run_id_info = TransferRunId.new(:info).run_id
          @run_id_party = TransferRunId.new(:party).run_id
          run_id_pdfs_on_aws = TransferRunId.new(:pdfs_on_aws).run_id

          md5_info_class = MD5Hash.new(columns:%w[court_id case_id case_name judge_name case_filed_date case_type])
          md5_pdfs_class = MD5Hash.new(columns:%w[court_id case_id source_type aws_link])


          loop do
            #p page
            offset = limit*page

            manual_cases = CasesWithPdfFromCSV_2.where(done:1).limit(limit).offset(offset)
            manual_case_id = manual_cases.map{|row| row.case_id}
            existed_cases = UsCaseInfoCourts.where(case_id:manual_case_id).map {|row| row.case_id.strip}
            manual_cases.each do |row|
              break if row.court_name.nil?
              court_info = UsCourtsTable.where(court_name: row.court_name.strip).first
              if court_info.nil? #and row.court_name.nil?
                p row.court_name
                next
              end
              next if  row.case_id.nil? or existed_cases.include?(row.case_id) #!court_info.old_court_id.nil?
              court_id = court_info.court_id #row.court_id ||
              if court_id.nil?
                p "WRONG: #{row.court_name}|#{court_info.court_id}"
                next
              end
              next if row.case_name.length>500
              # case_id_str = case_id.str if !case_id.nil?
              info = {
                court_id: court_id, case_id: row.case_id.strip,

                case_name: row.case_name, case_type: row.case_type,
                case_filed_date: row.case_filed_date,
                case_description: row.case_name,
                run_id: run_id_info, touched_run_id: run_id_info,
                created_by: 'Rylan Klatt',
                data_source_url: row.pdf,
                additional_or_old:1,

              }
              info[:md5_hash] = md5_info_class.generate(info)
              p info
              pdfs_on_aws = {
                court_id: court_id, case_id: row.case_id.strip,
                source_type: 'info', aws_link: row.pdf,
                run_id: run_id_pdfs_on_aws, touched_run_id: run_id_pdfs_on_aws,
                created_by: 'Rylan Klatt'
              }

              pdfs_on_aws[:md5_hash] = md5_pdfs_class.generate(pdfs_on_aws)
              p pdfs_on_aws
              party = []

              party+=(get_plaintiff_people(row, info))
              party+=(get_defendant_people(row, info))
              party+=(get_lawyers(row, info))

              insert_to_db({info:info, party: party,pdfs_on_aws:pdfs_on_aws })
            end
            page=page+1

            break if manual_cases.to_a.length<limit
          end
        end

        def court_staging_to_raw
          courts = {}
          StagingCourts.all().each do |row|
            courts[row.id] = row.external_id
          end
          courts
        end

        def get_plaintiff_people(row, info)
          party = []
          md5_class = MD5Hash.new(columns: %w[court_id case_id party_name party_type is_lawyer
                                                 party_law_firm party_description])
          [1,2,3].each do |i|
            plaintiff_name = "Plaintiff #{i} Name"
            break if row[plaintiff_name].nil?

            party.push({
                         court_id: info[:court_id], case_id: info[:case_id],
                         party_name: row[plaintiff_name],
                         party_type: "Plaintiff", is_lawyer: 0,
                         party_law_firm: nil,
                         run_id: @run_id_party, touched_run_id: @run_id_party,
                         created_by: 'Rylan Klatt'
                       })
            plaintiff_type = "Plaintiff #{i} Type"
            if row[plaintiff_type]!='Person'
              #party[-1][:party_law_firm] = row[plaintiff_name]
              party[-1][:party_description] = row[plaintiff_type]
            else
              #party[-1][:party_law_firm] = nil
              party[-1][:party_description] = row["Plaintiff #{i} Sex (if Person)"]
            end
            party[-1][:md5_hash] = md5_class.generate(party[-1])
          end
          party
        end

        def get_defendant_people(row, info)
          party = []
          md5_class = MD5Hash.new(columns: %w[court_id case_id party_name party_type is_lawyer party_description])
          [1,2,3].each do |i|
            defendant_name = "Defendant #{i} name"
            break if row[defendant_name].nil?

            party.push({
                         court_id: info[:court_id], case_id: info[:case_id],
                         party_name: row[defendant_name],
                         party_type: "Defendant", is_lawyer: 0,
                         party_law_firm: nil,
                         run_id: @run_id_party, touched_run_id: @run_id_party,
                         created_by: 'Rylan Klatt'
                       })
            plaintiff_type = "Defendant #{i} Type"
            if row[plaintiff_type]!='Person'
              #party[-1][:party_law_firm] = row[defendant_name]
              party[-1][:party_description] = row[plaintiff_type]
            else
              #party[-1][:party_law_firm] = nil
              party[-1][:party_description] = row["Defendant #{i} Sex (if Person)"]
            end
            party[-1][:md5_hash] = md5_class.generate(party[-1])
          end
          party
        end

        def get_lawyers(row, info)
          party = []
          md5_class = MD5Hash.new(columns: %w[court_id case_id party_name party_type is_lawyer
                                                 party_law_firm party_description])
          ["Plaintiff", "Defendant"].each do |party_type|
            [1,2,3].each do |i|
              plaintiff_lawyer_name = "#{party_type} Lawyer Name #{i}"
              break if row[plaintiff_lawyer_name].nil?

              party.push({
                           court_id: info[:court_id], case_id: info[:case_id],
                           party_name: row[plaintiff_lawyer_name],
                           party_type: "#{party_type} Lawyer", is_lawyer: 1,
                           party_law_firm: row["#{party_type} Lawyer #{i} Law Firm"],
                           party_description: nil,
                           run_id: @run_id_party, touched_run_id: @run_id_party,
                           created_by: 'Rylan Klatt'
                         })
              party[-1][:md5_hash] = md5_class.generate(party[-1])
            end
          end
          party
        end

        def insert_to_db(data)
          UsCasePartyCourts.insert_all(data[:party]) if !data[:party].empty?
          UsCasePdfsOnAwsCourts.insert(data[:pdfs_on_aws]) if !data[:pdfs_on_aws].nil?
          UsCaseInfoCourts.insert(data[:info]) if !data[:info].nil?
        end


      end


    end
  end
end