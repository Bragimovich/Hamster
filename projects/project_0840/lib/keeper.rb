# frozen_string_literal: true

require_relative '../models/ok_oklahoma_inmates'
require_relative '../models/ok_oklahoma_charges'
require_relative '../models/ok_oklahoma_inmate_additional_info'
require_relative '../models/ok_oklahoma_arrests'
require_relative '../models/ok_oklahoma_bonds'
require_relative '../models/ok_oklahoma_court_hearings'
require_relative '../models/ok_oklahoma_mugshots'
require_relative '../models/runs'


class Keeper < Hamster::Harvester
  attr_writer :data_hash

  def initialize
  super
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id
  end

  def store_inmate
    @inmate = digest_update(OkOklahomaInmates, @data_hash)
    @data_hash.merge!({inmate_id: @inmate.id})
  end

  def store_additional_info
    additional_info_arr= []
    @data_hash.each do |row, value|
      if row == (:height) || row == (:weight) || row == (:hair_color) || row == (:eye_color) || row == (:age)
        unless value.nil? || value.empty?
          hash = {
              key: row,
              value: value,
              inmate_id: @inmate.id,
              run_id: @run_id,
              touched_run_id: @run_id
          }
          hash.merge!({md5_hash: create_md5_hash(hash), data_source_url: "https://omsweb.public-safety-cloud.com/jtclientweb/jailtracker/index/Oklahoma_County_OK"})
          #additional_info_arr << hash
          digest_update(OkOklahomaInmateAdditionalInfo, hash)
        end
      end
    end
    #OkOklahomaInmateAdditionalInfo.insert_all(additional_info_arr)
  end

  def store_arrests
    unless @data_hash[:tables].nil?
      @arrest = []
      @data_hash[:tables][0].each do |row|
        row.merge!({inmate_id: @data_hash[:inmate_id]})
        @arrest << digest_update(OkOklahomaArrests, row)
      end
    end
  end

  def store_charges
    unless @data_hash[:tables].nil?
      @charge = []
      @data_hash[:tables][1].each_with_index do |row, index|
        row.merge!({arrest_id: @arrest[index].id})
        @charge << digest_update(OkOklahomaCharges, row)
      end
    end
  end

  def store_bonds
    unless @data_hash[:tables].nil?
      @data_hash[:tables][2].each_with_index do |row, index|
        row.merge!({arrest_id: @arrest[index].id})
        row.merge!({charge_id: @charge[index].id})
        digest_update(OkOklahomaBonds, row)
      end
    end
  end

  def store_court_hearings
    unless @data_hash[:tables].nil?
      @data_hash[:tables][3].each_with_index do |row, index|
        row.merge!({charge_id: @charge[index].id})
        @charge << digest_update(OkOklahomaCourtHearings, row)
      end
    end
  end

  def store_mugshots
    unless @data_hash[:original_link].nil?
      mugshot_link = store_to_aws(@data_hash[:original_link])
      @data_hash.merge!({aws_link: mugshot_link})
      digest_update(OkOklahomaMugshots, @data_hash)
    end
  end


  def store_to_aws(link)
    encoded_data = link.split(',')[1]
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account = :hamster)
    key = Digest::MD5.new.hexdigest(link)
    @aws_s3.put_file(Base64.decode64(encoded_data), "inmates/ok/oklahoma/#{key}.jpg")
  end

  def digest_update(object, h)
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash))

    if digest.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id, data_source_url: "https://omsweb.public-safety-cloud.com/jtclientweb/jailtracker/index/Oklahoma_County_OK", md5_hash: create_md5_hash(hash)})
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id, deleted: false) 
      digest
    end
  end

  def create_md5_hash(hash)
    str = ""
    hash.each do |field|
      unless field.include?(:data_source_url) || field.include?(:run_id) || field.include?(:touched_run_id) || field.include?(:md5_hash)
        str += field.to_s
      end
    end
    digest = Digest::MD5.new.hexdigest(str)
  end

  def update_delete_status
    models = [OkOklahomaInmates, OkOklahomaInmateAdditionalInfo, OkOklahomaArrests, OkOklahomaCharges, OkOklahomaBonds, OkOklahomaCourtHearings, OkOklahomaMugshots]
    models.each do |model|
      model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    end
  end
  
  def finish
    @run_object.finish
  end
end
