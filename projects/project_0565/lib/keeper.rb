require_relative '../models/vt_sc_case_info'
require_relative '../models/vt_sc_case_pdfs_on_aws'
require_relative '../models/vt_sc_case_party'
require_relative '../models/vt_sc_case_additional_info'
require_relative '../models/vt_sc_case_relations_activity_pdf'
require_relative '../models/vt_sc_case_activities'
require_relative '../models/vt_sc_case_run'

class Keeper

  attr_reader 'run_id'

  begin
    def initialize
      @s3 = AwsS3.new(bucket_key = :us_court)
      @scraper = Scraper.new
      @run_object = RunId.new(VtScCaseRun)
      @run_id = @run_object.run_id
      @court_id = 346
      @pdf_parser = PdfParser.new
    end

    def save_files_to_aws(url_file, case_id)
      begin
        key_start = "us_courts_expansion/346/#{case_id}/"
        body = @scraper.fetch_pdf_data(url_file)
        key = key_start + Time.now.to_i.to_s + '.pdf'
        @s3.put_file(body, key, metadata={url: url_file})
      rescue Exception => e
        return ''
        logger.error e.full_message
      end
    end

    def create_md5_hash(hash, md5)
      md5.generate(hash)
      md5.hash
    end

    def check_record_exits(case_name)
      VtScCaseInfo.where(:case_name => case_name)
    end

    def vt_sc_case_info_hash(info_hash, case_id)
      pdf_data_hash = info_hash['pdf_data']
      case_name = info_hash['case_name'].gsub(/[\n\t]/, " ").squeeze("").strip.split("  ").first
      case_id = case_id
      if pdf_data_hash.nil? || pdf_data_hash.empty?
        vt_sc_case_info_hash = {
          court_id: @court_id,
          case_name: case_name,
          case_id: case_id,
        }
      else
        vt_sc_case_info_hash = {
          run_id: @run_id,
          court_id: @court_id,
          case_name: case_name,
          case_id: case_id,
          case_description: nil,
          disposition_or_status: nil,
          case_filed_date: pdf_data_hash[:case_filed_date],
          status_as_of_date: pdf_data_hash[:status_as_of_date].empty? ? nil : pdf_data_hash[:status_as_of_date],
          judge_name: pdf_data_hash[:judge_name].empty? ? nil : pdf_data_hash[:judge_name],
          lower_court_id: nil,
          lower_case_id: nil,
          touched_run_id: @run_id
        }
      end
      md5 = MD5Hash.new(table: :info)
      md5_info_hash = {
        md5_hash: create_md5_hash(vt_sc_case_info_hash, md5),
      }
      vt_sc_case_info_hash.merge!(md5_info_hash)
      VtScCaseInfo.insert(vt_sc_case_info_hash)
    end

    def vt_sc_case_additional_info(info_hash, case_id)
      pdf_data_hash = info_hash['pdf_data']
      case_id = case_id
      vt_sc_case_additional_info = {
        run_id: @run_id,
        court_id: @court_id,
        case_id: case_id,
        lower_court_name: pdf_data_hash[:lower_court_name].empty? ? nil : pdf_data_hash[:lower_court_name],
        lower_case_id: nil,
        lower_judge_name: nil,
        lower_judgement_date: pdf_data_hash[:case_filed_date],
        lower_link: nil,
        disposition: nil,
        touched_run_id: @run_id
      }
      md5 = MD5Hash.new(columns:%i[run_id court_id case_id lower_court_name lower_case_id lower_judge_name lower_judgement_date lower_link disposition])
      md5_info_hash = {
        md5_hash: create_md5_hash(vt_sc_case_additional_info, md5),
      }
      vt_sc_case_additional_info.merge!(md5_info_hash)
      VtScCaseAdditionalInfo.insert(vt_sc_case_additional_info) 
    end

    def vt_sc_case_party(info_hash, count, case_id)
      pdf_data_hash = info_hash['pdf_data']
      case_id = case_id
      count = count
      vt_sc_case_attorney = {
        run_id: @run_id,
        court_id: @court_id,
        case_id: case_id,
        is_lawyer: 1,
        party_name: pdf_data_hash[:party_name] || nil,
        party_type: pdf_data_hash[:party_type] || nil,
        party_law_firm: pdf_data_hash[:party_law_firm] || nil,
        party_city: pdf_data_hash[:party_city] || nil,
        party_description: pdf_data_hash[:party_description] || nil,
        touched_run_id: @run_id
      }
      md5 = MD5Hash.new(columns:%i[run_id court_id case_id is_lawyer party_name party_type party_law_firm party_city party_description])
      md5_info_attorney = {
        md5_hash: create_md5_hash(vt_sc_case_attorney, md5),
      }

      vt_sc_case_attorney.merge!(md5_info_attorney)
      VtScCaseParty.insert(vt_sc_case_attorney) if vt_sc_case_attorney[:party_name].nil? == false
      case_name = info_hash['case_name'].gsub(/[\n\t]/, " ").squeeze("").strip
      party_case_name = case_name.split("  ").first
      if count == 0
        party_name = party_case_name.split(" v. ").first
      else
        party_name = party_case_name.split(" v. ").last
      end
      vt_sc_case_participant = {
        run_id: @run_id,
        court_id: @court_id,
        case_id: case_id,
        is_lawyer: 0,
        party_name: party_name || nil,
        party_type: pdf_data_hash[:party_type] || nil,
        touched_run_id: @run_id
      }     

      md5 = MD5Hash.new(table: :party)
      md5_info_participant = {
        md5_hash: create_md5_hash(vt_sc_case_participant, md5),
      }
      vt_sc_case_participant.merge!(md5_info_participant)
      VtScCaseParty.insert(vt_sc_case_participant)
    end

    def vt_sc_case_pdfs_on_aws(info_hash, case_id)
      case_id = case_id
      vt_sc_case_pdfs_on_aws = {
        run_id: @run_id,
        court_id: @court_id,
        case_id: case_id,
        source_type: 'activity',
        aws_link: info_hash['aws_url'],
        source_link: info_hash['source_link'],
        touched_run_id: @run_id
      }
      md5 = MD5Hash.new(table: :pdfs_on_aws)
      md5_info_hash = {
        md5_hash: create_md5_hash(vt_sc_case_pdfs_on_aws, md5),
      }
      vt_sc_case_pdfs_on_aws.merge!(md5_info_hash)
      VtScCasePdfsOnAws.insert(vt_sc_case_pdfs_on_aws)
      VtScCasePdfsOnAws.last
    end

    def vt_sc_case_activities(info_hash, case_id)
      date = info_hash['activity_date']
      activity_date = Date.strptime(date, "%m/%d/%Y").strftime("%Y-%m-%d")
      case_id = case_id
      vt_sc_case_activities = {
        run_id: @run_id,
        court_id: @court_id,
        case_id: case_id,
        activity_date: activity_date,
        activity_decs: nil,
        activity_type: 'Opinion',
        file: info_hash['source_link'],
        touched_run_id: @run_id
      }
      md5 = MD5Hash.new(table: :activities)
      md5_vt_sc_case_activities_hash = {
        md5_hash: create_md5_hash(vt_sc_case_activities, md5),
      }
      vt_sc_case_activities.merge!(md5_vt_sc_case_activities_hash)
      VtScCaseActivities.insert(vt_sc_case_activities)
      VtScCaseActivities.last
    end

    def case_relations_activity_pdf(case_activities_hash, pdfs_on_aws_hash)
      case_relations_activity_pdf = {
        case_activities_md5: case_activities_hash,
        case_pdf_on_aws_md5: pdfs_on_aws_hash,
      }
      md5 = MD5Hash.new(columns:%i[case_activities_md5 case_pdf_on_aws_md5])
      md5_case_relations_activity_pdf_hash = {
        md5_hash: create_md5_hash(case_relations_activity_pdf, md5),
      }
      case_relations_activity_pdf.merge!(md5_case_relations_activity_pdf_hash)
      VtScCaseRelationsActivityPdf.insert(case_relations_activity_pdf)
    end

    def parse_data(sub_page_data, type, count, case_id)
      sub_page_data.each do |data|
        store_data(data, type, count, case_id)
      end
    end

    def store_data(data, type, count, case_id)
      pdf_data_hash = data['pdf_data']
      if pdf_data_hash.nil? || pdf_data_hash.empty?
        vt_sc_case_info_hash(data)
      else
        if type == "Plaintiff-Appellant"
          vt_sc_case_info_hash(data, case_id)
          vt_sc_case_additional_info(data, case_id)
            vt_sc_case_party(data, count, case_id)
          vt_case_activities = vt_sc_case_activities(data, case_id)
          case_activities_hash = vt_case_activities[:md5_hash]
          pdfs_on_aws = vt_sc_case_pdfs_on_aws(data, case_id)
          aws_pdf_hash = pdfs_on_aws[:md5_hash]
          case_relations_activity_pdf(case_activities_hash, aws_pdf_hash)
        else
          vt_sc_case_party(data, count, case_id)
        end
      end
    end
  rescue
    logger.error 'issue while merging hash'
  end
end
