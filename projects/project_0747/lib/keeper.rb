# frozen_string_literal: true

require_relative '../models/runs'
require_relative '../models/arkansas_inmates'
require_relative '../models/arkansas_arrests'
require_relative '../models/arkansas_holding_facilities_addresses'
require_relative '../models/arkansas_holding_facilities'
require_relative '../models/arkansas_charges'
require_relative '../models/arkansas_inmate_ids'
require_relative '../models/arkansas_inmate_ids_additional'
require_relative '../models/arkansas_inmate_aliases'
require_relative '../models/arkansas_mugshots'
require_relative '../models/arkansas_inmate_additional_info'
require_relative '../models/arkansas_court_hearings'
require_relative '../models/arkansas_court_hearings_additional'
require_relative '../models/arkansas_charges_additional'
require_relative '../models/arkansas_disciplinary_violations'
require_relative '../models/arkansas_program_achievements'
require_relative '../models/arkansas_inmates_url'



class Keeper < Hamster::Harvester
  attr_reader :run_id, :full_array
  def initialize
    super
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id
    @data = []
  end

  def store_url(inmate_list)
    ArkansasInmatesUrl.insert_all(inmate_list)
  end

  def clear_data
    @data.clear
  end

  def fill_arr(hash)
    @full_array = false
    @data << hash
    @full_array = true if @data.count >= 200
  end

  def store_inmates
    return if @data.count.zero?
    @data.map { |hash| hash[:inmate].merge!({md5_hash: create_md5_hash(hash[:inmate])}) }
    ArkansasInmates.upsert_all(@data.map { |el| el[:inmate]})
    @inmate = @data.map { |hash| ArkansasInmates.where(md5_hash: hash[:inmate][:md5_hash]).pluck(:id).join(',') }
  end

  def store_disciplinary_violations
    @data.each_with_index do |arr, index|
      unless arr[:disciplinary_violations_arr].nil?
        arr[:disciplinary_violations_arr].each do |hash| 
          hash[:inmate_id] = @inmate[index].to_i
          hash.merge!({md5_hash: create_md5_hash(hash)})
        end
      end
    end
    ArkansasDisciplinaryViolations.upsert_all(((@data.map { |el| el[:disciplinary_violations_arr] }).compact.flatten))
  end

  def store_program_achievements
    @data.each_with_index do |arr, index|
      unless arr[:program_achievements_arr].nil?
        arr[:program_achievements_arr].each do |hash| 
          hash[:inmate_id] = @inmate[index].to_i
          hash.merge!({md5_hash: create_md5_hash(hash)})
        end
      end
    end
    ArkansasProgramAchievements.upsert_all(((@data.map { |el| el[:program_achievements_arr] }).compact.flatten))
  end 

  def store_arrests
    @data.each_with_index { |arr, index| arr[:arrest_arr].map { |hash| hash[:inmate_id] = @inmate[index].to_i} }
    @data.map { |arr| arr[:arrest_arr].map { |hash| hash.merge!({md5_hash: create_md5_hash(hash)})} }
    ArkansasArrests.upsert_all(((@data.map { |el| el[:arrest_arr] })).compact.flatten)
    @arrest = @data.map { |arr| ArkansasArrests.where(md5_hash: arr[:arrest_arr].map { |hash| hash[:md5_hash] }).pluck(:id).join(',') }
  end

  def store_holding_facilities_addresses
    @data.map { |el| el[:addresses_hash].merge!({md5_hash: create_md5_hash(el[:addresses_hash])})}
    ArkansasHoldingFacilitiesAddresses.upsert_all(@data.map { |el| el[:addresses_hash]})
    @address = @data.map { |hash| ArkansasHoldingFacilitiesAddresses.where(md5_hash: hash[:addresses_hash][:md5_hash]).pluck(:id).join(',') }
  end

  def store_holding_facilities
    @data.each_with_index { |hash, index| hash[:holding_facilities_hash][:arrest_id] = @arrest[index].to_i }
    @data.each_with_index { |hash, index| hash[:holding_facilities_hash][:holding_facilities_addresse_id] = @address[index].to_i }
    ArkansasHoldingFacilities.upsert_all(@data.map { |el| el[:holding_facilities_hash]})
  end

  def store_inmate_ids
    @data.each_with_index { |hash, index| hash[:inmate_ids_hash][:inmate_id] = @inmate[index].to_i }
    @data.map { |el| el[:inmate_ids_hash].merge!({md5_hash: create_md5_hash(el[:inmate_ids_hash])})}
    ArkansasInmateIds.upsert_all(@data.map { |el| el[:inmate_ids_hash]})
    @inmate_ids = @data.map { |hash| ArkansasInmateIds.where(md5_hash: hash[:inmate_ids_hash][:md5_hash]).pluck(:id).join(',') }
  end

  def store_inmate_ids_additional
    @data.each_with_index { |arr, index| arr[:inmate_ids_additional_arr].map { |hash| hash[:arkansas_inmate_ids_id] = @inmate_ids[index].to_i} }
    @data.map { |arr| arr[:inmate_ids_additional_arr].map { |hash| hash.merge!({md5_hash: create_md5_hash(hash)})} }
    ArkansasInmateIdsAdditional.insert_all(((@data.map { |el| el[:inmate_ids_additional_arr] }).compact.flatten))
  end

  def store_aliases
    @data.each_with_index do |arr, index|
      unless arr[:inmate_aliases_arr].nil?
        arr[:inmate_aliases_arr].each do |hash|
          hash[:inmate_id] = @inmate[index].to_i
          hash.merge!({md5_hash: create_md5_hash(hash)})
        end
      end
    end
    ArkansasInmateAliases.upsert_all(((@data.map { |el| el[:inmate_aliases_arr] }).compact.flatten))
  end

  def store_mugshots
    @data.each_with_index do |hash, index|
      unless hash[:mugshots_hash].nil?
        hash[:mugshots_hash][:inmate_id] = @inmate[index].to_i
        hash[:mugshots_hash].merge!({md5_hash: create_md5_hash(hash[:mugshots_hash])})
        digest = ArkansasMugshots.find_by(md5_hash: create_md5_hash( hash[:mugshots_hash]), deleted: false)
        if digest.nil?
          hash[:mugshots_hash].merge!({run_id: @run_id, touched_run_id: @run_id, md5_hash: create_md5_hash( hash[:mugshots_hash])})
          ArkansasMugshots.store( hash[:mugshots_hash])
        else
          digest.update(touched_run_id: @run_id)
          digest
        end
      end
    end
  end

  def store_additional_info
    @data.each_with_index { |arr, index| arr[:inmate_additional_info_arr].map { |hash| hash[:inmate_id] = @inmate[index].to_i} }
    @data.map { |arr| arr[:inmate_additional_info_arr].map { |hash| hash.merge!({md5_hash: create_md5_hash(hash)})} }
    ArkansasInmateAdditionalInfo.insert_all(((@data.map { |el| el[:inmate_additional_info_arr] }).compact.flatten))
  end

  def store_charges
    @data.each_with_index { |arr, index| arr[:arkansas_charges][0].map { |hash| hash[:inmate_id] = @inmate[index].to_i} }
    @data.map { |arr| arr[:arkansas_charges][0].map { |hash| hash.merge!({md5_hash: create_md5_hash(hash)})} }
    ArkansasCharges.upsert_all(((@data.map { |el| el[:arkansas_charges][0] }).compact.flatten))
    charge = @data.map { |arr| ArkansasCharges.where(md5_hash: arr[:arkansas_charges][0].map { |hash| hash[:md5_hash] }).pluck(:id).join(',') }
    @data.each_with_index { |arr, index| arr[:arkansas_charges][1].map { |hash| hash[:charge_id] = charge[index].to_i} }
    @data.each_with_index { |arr, index| arr[:arkansas_charges][1].map { |hash| hash.merge!({md5_hash: create_md5_hash(hash)})} }
    ArkansasCourtHearings.upsert_all(((@data.map { |el| el[:arkansas_charges][1] }).compact.flatten))
    court_hearings = @data.map { |arr| ArkansasCourtHearings.where(md5_hash: arr[:arkansas_charges][1].map { |hash| hash[:md5_hash] }).pluck(:id).join(',') }
    @data.each_with_index { |arr, index| arr[:arkansas_charges][2].map { |hash| hash[:arkansas_court_hearings_id] = court_hearings[index].to_i} }
    @data.map { |arr| arr[:arkansas_charges][2].map { |hash| hash.merge!({md5_hash: create_md5_hash(hash)})} }
    ArkansasCourtHearingsAdditional.insert_all(((@data.map { |el| el[:arkansas_charges][2] }).compact.flatten))
    @data.each_with_index { |arr, index| arr[:arkansas_charges][3].map { |hash| hash[:inmate_id] = @inmate[index].to_i} }
    @data.map { |arr| arr[:arkansas_charges][3].map { |hash| hash.merge!({md5_hash: create_md5_hash(hash)})} }
    ArkansasCharges.upsert_all(((@data.map { |el| el[:arkansas_charges][3] }).compact.flatten))
    charge_a = @data.map { |arr| ArkansasCharges.where(md5_hash: arr[:arkansas_charges][3].map { |hash| hash[:md5_hash] }).pluck(:id).join(',') }
    @data.each_with_index { |arr, index| arr[:arkansas_charges][4].map { |hash| hash[:arkansas_charges_id] = charge_a[index].to_i} }
    @data.map { |arr| arr[:arkansas_charges][4].map { |hash| hash.merge!({md5_hash: create_md5_hash(hash)})} }
    ArkansasChargesAdditional.insert_all(((@data.map { |el| el[:arkansas_charges][4] }).compact.flatten))
  end

  def update_aws_link(link, id)
    ArkansasMugshots.where(id: id).update(aws_link: link)
  end

  def update_delete_status
    models = [ArkansasArrests, ArkansasChargesAdditional, ArkansasCharges, ArkansasCourtHearingsAdditional, ArkansasCourtHearings, ArkansasHoldingFacilitiesAddresses,
              ArkansasHoldingFacilities, ArkansasInmateAdditionalInfo, ArkansasInmateAliases, ArkansasInmateIdsAdditional, ArkansasInmateIds, ArkansasInmates,
              ArkansasMugshots, ArkansasProgramAchievements, ArkansasDisciplinaryViolations
              ]
    models.each do |model|
      model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    end
  end

  def finish
    @run_object.finish
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
end
