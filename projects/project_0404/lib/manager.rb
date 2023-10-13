# frozen_string_literal: true

require_relative '../lib/abstract_scraper'
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  COURTS = {94 => 428, 96 => 315}
  
  def initialize(**params)
    super
    @s3                   = AwsS3.new(bucket_key = :us_court)
    @keeper               = Keeper.new
    @run_id               = @keeper.run_id
    @parser               = Parser.new
    @scraper              = Scraper.new
  end

  def scrape
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} Started")
    COURTS.keys.each do |court_item_id|
      scraper.scrape(court_item_id) do |data_hash|
        parser.content = data_hash
        begin
          parser.init_base_details
        rescue => e
          Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} #{e.message}")
          next
        end
        keeper.store_data(parser.info_hash, InSaacCaseInfo)
        keeper.store_data(parser.additional_info_data, InSaacCaseAdditionalInfo) 
        keeper.store_data(parser.party_data, InSaacCaseParty)
        activities = parser.activities_data
        keeper.store_data(activities, InSaacCaseActivities)
        activities.each { |hash| store_pdf_on_aws(hash) }
      end
    end
    after_store
  end

  private

  attr_reader :scraper, :parser, :keeper, :run_id

  def store_pdf_on_aws(activity_hash)
    case_id  = activity_hash[:case_id]
    court_id = activity_hash[:court_id]
    url      = activity_hash[:pdf_url]
    filename = activity_hash[:file]
    return unless url

    aws_public_link = save_to_aws(url: url, case_id: case_id, court_id: court_id, filename: filename)

    if aws_public_link&.present?
      aws_hash = {
        court_id: activity_hash[:court_id],
        case_id: activity_hash[:case_id],
        source_link: filename,
        aws_link: aws_public_link,
        source_type: 'activity',
        data_source_url: Scraper::ORIGIN
      }

      keeper.store_data(aws_hash, InSaacCasePdfsOnAws)
      store_relations_hash(activity_hash, aws_hash)
    end
  end

  def save_to_aws(**params)
    filename = params[:filename].strip.delete_suffix('.pdf')
    body = Scraper.new.download_pdf(params[:url])
    metadata = {case_id: params[:case_id], court_id: params[:court_id]}
    key = "us_courts/#{params[:court_id]}/#{params[:case_id]}/#{filename}.pdf"
    @s3.find_files_in_s3(key).empty? ? @s3.put_file(body, key, metadata) : "https://court-cases-activities.s3.amazonaws.com/#{key}"
  end

  def store_relations_hash(activity_hash, aws_hash)
    hash = {}
    hash_1 = InSaacCaseActivities.flail { |k| [k, activity_hash[k]] } 
    hash_2 = InSaacCasePdfsOnAws.flail  { |k| [k, aws_hash[k]] }

    hash[:case_activities_md5]  = @keeper.add_md5_hash(hash_1, result: 'only_md_5')
    hash[:case_pdf_on_aws_md5]  = @keeper.add_md5_hash(hash_2, result: 'only_md_5')
    keeper.store_data(hash, InSaacCaseRelationsActivityPdf)
  end

  def after_store
    models = [
      InSaacCaseInfo, InSaacCaseAdditionalInfo, InSaacCaseParty, InSaacCaseActivities, 
      InSaacCasePdfsOnAws, InSaacCaseRelationsActivityPdf
    ]
    keeper.update_delete_status(*models)
    keeper.finish
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} finished")
  end
end
