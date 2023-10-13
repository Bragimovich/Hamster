# frozen_string_literal: true

require_relative '../models/florida_arrestees'
require_relative '../models/florida_advance_arrestees'
require_relative '../models/florida_arrestee_aliases'
require_relative '../models/florida_makrs'
require_relative '../models/florida_vehicles_info'
require_relative '../models/florida_victim_info'
require_relative '../models/florida_states'
require_relative '../models/florida_cities'
require_relative '../models/florida_zips'
require_relative '../models/florida_addresses'
require_relative '../models/florida_offense'
require_relative '../models/florida_arrestees_address'
require_relative '../models/florida_vessel_info'
require_relative '../models/florida_mugshots'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  attr_writer :data_hash

  def initialize(options)
    unless options[:store_img]
      @run_object =  RunId.new(Runs)
      @run_id = @run_object.run_id
    end
  end

  def store_arrestees
    @arrestee = digest_update(FloridaArrestees, @data_hash)
    @data_hash.merge!({arrestee_id: @arrestee.id})
  end

  def store_advance_arrestees
    digest_update(FloridaAdvanceArrestees, @data_hash)
  end

  def store_aliases
    @data_hash[:aliases].split(',').each do |name|
      unless name.include?("Not Available")
        digest_update(FloridaArresteeAliases, { alias_full_name: name, arrestee_id: @arrestee.id })
      end
    end
  end

  def store_maskrs
    @data_hash[:tattoo].each do |row|
      unless row[:type_marks].include?('None Reported') || row[:type_marks].include?('Not Available')
        row.merge!({arrestee_id: @arrestee.id})
        digest_update(FloridaMakrs, row)
      end
    end
  end

  def store_victim_info
    @data_hash[:victim_info].each do |row|
      unless row[:gender].include?("No records found.")
        row.merge!({arrestee_id: @arrestee.id})
        digest_update(FloridaVictimInfo, row)
      end
    end
  end

  def store_state
    @data_hash[:address].each do |row|
      unless row[:full_address].empty? || row[:state].nil?
        states = update_unique_name(FloridaStates, { name: row[:state]})
        row.merge!({states_id: states.id })
        @data_hash.merge!({states_id: states.id })
      end
    end
  end

  def store_cities
    @data_hash[:address].each do |row|
      unless row[:full_address].empty? || row[:city].nil?
        cities = update_unique_name(FloridaCities, { name: row[:city], states_id: row[:states_id]})
        row.merge!({cities_id: cities.id })
      end
    end
  end

  def store_zips
    @data_hash[:address].each do |row|
      unless row[:full_address].empty? || row[:zip].nil?
        zips = update_unique_name(FloridaZips, { code: row[:zip]})
        row.merge!({zips_id: zips.id})
      end
    end
  end

  def store_addresses
    @data_hash[:address].each do |row|
      unless row[:full_address].empty?
        @addresses = digest_update(FloridaAddresses, row)
        row.merge!({addresses_id: @addresses.id})
      end
    end
  end

  def store_vehicles_info
    @data_hash[:vehicle_info].each do |row|
      unless row[:make].include?('No registered/owned vehicle information on file for this subject')
        row.merge!({arrestee_id: @arrestee.id, states_id: @data_hash[:states_id] })
        digest_update(FloridaVehiclesInfo, row)
      end
    end
  end

  def store_arrestees_address
    FloridaArresteesAddress.insert({addresses_id: @addresses.id, arrestee_id: @arrestee.id}) rescue nil
  end

  def store_offense
    @data_hash[:crime_info].each do |row|
      unless row[:date].nil?
        city_state = row[:jurisdiction].gsub(",,",",").split(',')
        if city_state.size == 1
          if city_state.first.size > 2
            cities = update_unique_name(FloridaCities, { name: city_state.first.strip }) rescue nil
          else
            states = update_unique_name(FloridaStates, { name: city_state.first.strip }) rescue nil
          end
        elsif city_state.size == 2 || city_state.size == 3
          states = update_unique_name(FloridaStates, { name: city_state.last.strip })
          cities = update_unique_name(FloridaCities, { name: city_state.first.strip, states_id: states.id  })
        end
        row.merge!(states_id: states.id, arrestee_id: @arrestee.id)
        digest_update(FloridaOffense, row)
      end
    end
  end

  def store_vessel_info
    @data_hash[:vessel_info].each do |row|
      unless row[:make].include?("No registered/owned vessel information on file for this subject")
        row.merge!({arrestee_id: @arrestee.id, states_id: @data_hash[:states_id] })
        digest_update(FloridaVesselInfo, row)
      end
    end
  end

  def store_mugshots
    digest_update(FloridaMugshots, @data_hash)
  end

  def update_aws_link(link, id)
    FloridaMugshots.where(id: id).update(aws_link: link)
  end

  def update_delete_status
    FloridaArrestees.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaAdvanceArrestees.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaArresteeAliases.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaMakrs.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaVictimInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaAddresses.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaVehiclesInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaOffense.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaVesselInfo.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    FloridaMugshots.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def finish
    @run_object.finish
  end

  def update_unique_name(object, h)
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash))
    if digest.nil?
      hash.merge!({md5_hash: create_md5_hash(hash)})
      object.store(hash)
    else
      digest
    end
  end
  
  def digest_update(object, h)
    source_url =  "https://offender.fdle.state.fl.us/offender/sops/offenderSearch.jsf"
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash))
    if digest.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id, data_source_url: source_url,  md5_hash: create_md5_hash(hash)})
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id, deleted: false)
      digest
    end
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end
end
