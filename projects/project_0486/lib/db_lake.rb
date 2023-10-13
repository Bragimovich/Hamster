# frozen_string_literal: true
require_relative '../modules/models_helper'
require_relative '../models/il_lake__arrestee_aliases'
require_relative '../models/il_lake__arrestee_ids'
require_relative '../models/il_lake__arrestees'
require_relative '../models/il_lake__arrests'
require_relative '../models/il_lake__bonds'
require_relative '../models/il_lake__charges'
require_relative '../models/il_lake__court_hearing'
require_relative '../models/il_lake__holding_facilities'
require_relative '../models/il_lake__index'
require_relative '../models/il_lake__runs'
require_relative '../models/il_lake__arrestee_addresses'
require_relative '../models/il_lake__mugshots'

class DbLake
  attr_reader :runs, :info, :activities

  def initialize
    super
    @runs = IlLakeRuns.create

    @associations__mugshots = {
      aws_link: :aws_link,
      original_link: :photo
    }

    @associations__arrestees  = {
      full_name: :name,
      sex: :sex
    }

    @associations__arrestee_addresses = {
      full_address: :address
    }

    @associations__arrests = {
      status: :status,
      booking_date: :booked,
      booking_number: :booking
    }

    @associations__charges = {
      disposition: :disposition,
      description: :offense,
      offense_date: :confined
    }

    @associations__bonds = {
      bond_type: :bond_type,
      bond_amount: :bond_amount
    }

    @associations__court_hearings = {
      court_date: :court_date,
      court_time: :court_time
    }

    @associations__holding_facilities = {
      facility: :location
    }

    @associations__index = {
      booking_number: :booking_number,
      name: :name,
      sex: :sex,
      booked: :booked,
      location: :location,
      data_source_url: :url
    }

  end

  def gen_hash_table(index, assoc)
    @create_hash = {}
    assoc.each {|key, value| @create_hash.merge!({key => index[value]})}
  end

  def insert_index(index)
    gen_hash_table(index, @associations__index)
    @runs.index.create(@create_hash)
  end

  def insert_content(args={})
    index = args[:index]
    content = args[:content]
    # info_assoc = args[:info_assoc]
    # activities_assoc = args[:activities_assoc]
    content.merge!(index)
    gen_hash_table(content, @associations__arrestees)
    @create_hash.merge!({ data_source_url: index[:url] })

    info_new = @runs.info.create(@create_hash)
    if info_new.errors.size > 0
      info_new = IlLakeArrestees.find_by(md5_hash: info_new.gen_md5)
      info_new.update(touched_run_id: @runs.id)
    end

    gen_hash_table(content, @associations__arrestee_addresses)
    @create_hash.merge!({ run_id: @runs.id, data_source_url: index[:url], touched_run_id: @runs.id })
    info_address = info_new.addresses.create(@create_hash)
    if (info_address.errors.size > 0)
      info_address = info_new.addresses.find_by(md5_hash: info_address.gen_md5)
      info_address.update(touched_run_id: @runs.id)
    end

    gen_hash_table(content, @associations__arrests)
    @create_hash.merge!({run_id: @runs, touched_run_id: @runs.id, data_source_url: index[:url] })
    info_arrest = info_new.arrests.create(@create_hash)
    if info_arrest.errors.size > 0
      info_arrest = info_new.arrests.find_by(md5_hash: info_arrest.gen_md5)
      info_arrest.update(touched_run_id: @runs.id)
    end

    gen_hash_table(content, @associations__mugshots)
    @create_hash.merge!({run_id: @runs.id, touched_run_id: @runs.id, data_source_url: index[:url] })
    info_mugshots = info_new.mugshots.create(@create_hash)
    if info_mugshots.errors.size > 0
      info_mugshots = info_new.mugshots.find_by(md5_hash: info_mugshots.gen_md5)
      info_mugshots.update(touched_run_id: @runs.id)
    end


    gen_hash_table(content, @associations__holding_facilities)
    @create_hash.merge!({ run_id: @runs.id, data_source_url: index[:url], touched_run_id: @runs.id})
    holding_facilities = info_arrest.holding_facilities.create(@create_hash)
    if holding_facilities.errors.size > 0
      holding_facilities = info_arrest.holding_facilities.find_by(md5_hash: holding_facilities.gen_md5)
      holding_facilities.update(touched_run_id: @runs.id)
    end



    content[:activities].each_with_index do |active, number_activity|

      gen_hash_table(active, @associations__charges)
      @create_hash.merge!({ run_id: @runs.id, touched_run_id: @runs.id, data_source_url: index[:url]})
      arrest_charge = info_arrest.charges.create(@create_hash)
      if arrest_charge.errors.size > 0
        arrest_charge = info_arrest.charges.find_by(md5_hash: arrest_charge.gen_md5)
        arrest_charge.update(touched_run_id: @runs.id)
      end

      gen_hash_table(active, @associations__bonds)
      @create_hash.merge!({ run_id: @runs.id, touched_run_id: @runs.id, charge_id: arrest_charge.id, data_source_url: index[:url]})
      arrest_bonds = info_arrest.bonds.create(@create_hash)
      if arrest_bonds.errors.size > 0
        arrest_bonds = info_arrest.bonds.find_by(md5_hash: arrest_bonds.gen_md5)
        arrest_bonds.update(touched_run_id: @runs.id)
      end

      gen_hash_table(active, @associations__court_hearings)
      @create_hash.merge!({ run_id: @runs.id, touched_run_id: @runs.id, data_source_url: index[:url]})
      court__hearing = arrest_charge.court_hearing.create(@create_hash)
      if court__hearing.errors.size > 0
        court__hearing = arrest_charge.court_hearing
        court__hearing.update(touched_run_id: @runs.id)
      end
    end

  end
  def finish
    @runs.update(status: "finished")
  end

  def finish_error
    @runs.update(status: "error")
  end
end
