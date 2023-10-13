require_relative '../models/wv_sc_case_info'
require_relative '../models/wv_sc_case_pdfs_on_aws'
require_relative '../models/wv_sc_case_party'
require_relative '../models/wv_sc_case_additional_info'
require_relative '../models/wv_sc_case_relations_activity_pdf'
require_relative '../models/wv_sc_case_activities'


class Keeper

  def initialize(**options)
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
    @scraper = Scraper.new
  end

  def save_files_to_aws(url_file, case_id)
    begin
      key_start = "us_courts_expansion/349/#{case_id}/"
      body = @scraper.fetch_pdf_data(url_file)
      key = key_start + Time.now.to_i.to_s + '.pdf'
      @s3.put_file(body, key, metadata={url: url_file})
    rescue Exception => e
      return ''
      puts e.full_message
    end
  end

  def check_record_exits(case_id)
    WvScCaseInfo.where(:case_id=> case_id)
  end

  def info_hash(sc_case_info_hash)
    WvScCaseInfo.insert(sc_case_info_hash)
  end

  def additional_info(sc_case_additional_info)
    WvScCaseAdditionalInfo.insert(sc_case_additional_info)
  end

  def case_party(info_hash)
    WvScCaseParty.insert(info_hash)
  end

  def pdfs_on_aws(sc_case_pdfs_on_aws)
    WvScCasePdfsOnAws.insert(sc_case_pdfs_on_aws)
    WvScCasePdfsOnAws.last
  end

  def case_activities(wv_sc_case_activities)
    WvScCaseActivities.insert(wv_sc_case_activities)
    WvScCaseActivities.last
  end

  def relations_activity_pdf(case_relations_activity_pdf)
    WvScCaseRelationsActivityPdf.insert(case_relations_activity_pdf)
  end

end
