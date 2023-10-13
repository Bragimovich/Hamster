require_relative '../models/nd_doc_arrests.rb'
require_relative '../models/nd_doc_holding_facilities_addresses.rb'
require_relative '../models/nd_doc_holding_facilities.rb'
require_relative '../models/nd_doc_il_dupage_inmate_ids.rb'
require_relative '../models/nd_doc_inmates.rb'
require_relative '../models/nd_doc_mugshots.rb'
require_relative '../models/nd_doc_run.rb'


class Keeper < Hamster::Scraper
  def initialize
    @run_object = RunId.new(NdDocRun)
    @run_id = @run_object.run_id
    @s3 = AwsS3.new(:hamster, :hamster)
  end

  def store_data(data, run_id)
    data.each do |data_hash|
      begin
        nd_doc_inmates_params = {
          full_name: data_hash['full_name'],
          birthdate: data_hash['birthdate'].split('/').rotate(-1).reverse.join("/"),
          data_source_url: data_hash['data_source_url'],
          run_id: run_id,
          touched_run_id: run_id
        }
        md5_hash = md5_hash(nd_doc_inmates_params)
        nd_doc_inmates = NdDocInmates.find_or_create_by(nd_doc_inmates_params.merge(md5_hash: md5_hash))
        
        nd_doc_il_dupage_inmate_ids_params = {
          immate_id: nd_doc_inmates.id,
          number: data_hash['offender_id'],
          data_source_url: data_hash['data_source_url'],
          run_id: run_id,
          touched_run_id: run_id
        }
        md5_hash = md5_hash(nd_doc_il_dupage_inmate_ids_params)
        nd_doc_il_dupage_inmate_ids = NdDocIlDupageInmateIds.find_or_create_by(nd_doc_il_dupage_inmate_ids_params.merge(md5_hash: md5_hash))

        nd_doc_mugshots_params = {
          immate_id: nd_doc_inmates.id,
          original_link: data_hash['original_link'],
          data_source_url: data_hash['data_source_url'],
          run_id: run_id,
          touched_run_id: run_id
        }
        md5_hash = md5_hash(nd_doc_mugshots_params)
        aws_link = save_to_aws(nd_doc_mugshots_params[:original_link])
        nd_doc_mugshots = NdDocMugshots.find_or_create_by(nd_doc_mugshots_params.merge(md5_hash: md5_hash, aws_link: aws_link))

        nd_doc_arrests_params = {
          immate_id: nd_doc_inmates.id,
          data_source_url: data_hash['data_source_url'],
          run_id: run_id,
          touched_run_id: run_id
        }
        md5_hash = md5_hash(nd_doc_arrests_params)
        nd_doc_arrests = NdDocArrests.find_or_create_by(nd_doc_arrests_params.merge(md5_hash: md5_hash))

        nd_doc_holding_facilities_addresses_params = {
          full_address: data_hash['full_address'],
          street_address: data_hash['street_address'],
          city: data_hash['city'],
          zip: data_hash['zip'],
          run_id: run_id,
          touched_run_id: run_id
        }
        md5_hash = md5_hash(nd_doc_holding_facilities_addresses_params)
        nd_doc_holding_facilities_addresses = NdDocHoldingFacilitiesAddresses.find_or_create_by(nd_doc_holding_facilities_addresses_params.merge(md5_hash: md5_hash))

        nd_doc_holding_facilities_params = {
          arrest_id: nd_doc_arrests.id,
          holding_facilities_addresse_id: nd_doc_holding_facilities_addresses.id,
          facility: data_hash['facility'],
          planned_release_date: data_hash['planned_release_date'].split('/').rotate(-1).reverse.join("/"),
          data_source_url: data_hash['data_source_url'],
          run_id: run_id,
          touched_run_id: run_id
        }
        md5_hash = md5_hash(nd_doc_holding_facilities_params)
        nd_doc_holding_facilities = NdDocHoldingFacilities.find_or_create_by(nd_doc_holding_facilities_params.merge(md5_hash: md5_hash))  
      rescue StandardError => e
        next
      end
    end
  end

  def md5_hash(data)
    md5_hash = MD5Hash.new(columns: data.keys)
    md5_hash.generate(data)
  end

  def save_to_aws(link)
    key_start = "inmates/nd/dep_of_correction/"
    cobble = Dasher.new(:using=>:cobble, ssl_verify: false)
    body = cobble.get(link)
    file_name = link.gsub(/\?.+$/,'')[link.index(/[^\/]+?$/), link.length]
    key = key_start + file_name
    aws_link = @s3.put_file(body, key, metadata={ url: link })

    Hamster.logger.info  "  [+] PHOTO LOAD IN AWS!".green
    aws_link
  end

  def finish
    @run_object.finish
  end
end
