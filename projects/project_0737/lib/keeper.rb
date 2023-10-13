# frozen_string_literal: true
require_relative '../models/in_marion_arrests'
require_relative '../models/in_marion_bonds_additional'
require_relative '../models/in_marion_bonds'
require_relative '../models/in_marion_charges_additional'
require_relative '../models/in_marion_charges'
require_relative '../models/in_marion_court_hearings'
require_relative '../models/in_marion_holding_facilities'
require_relative '../models/in_marion_inmate_additional_info'
require_relative '../models/in_marion_inmate_ids_additional'
require_relative '../models/in_marion_inmate_ids'
require_relative '../models/in_marion_inmate_statuses'
require_relative '../models/in_marion_inmates'
require_relative '../models/in_marion_inmates_run'
require_relative '../models/in_marion_inmate_processed'
require_relative '../models/in_marion_inmate_aliases'
require_relative '../lib/scraper'

class Keeper
  
  attr_reader :run_id, :current_start

  def initialize
    super
    @run_object = RunId.new(InMarionInmatesRun)
    @run_id = @run_object.run_id
    @current_start = InMarionInmatesRun.find(run_id).current_start
  end

  def store(data)
    unless data[:inmate].nil?
      fill_default_fields(data[:inmate])
      inmate = insert_model(InMarionInmates, data[:inmate])
      # meta insertion
      md5_hash = MD5Hash.new(columns: [:inmate_id])
      InMarionInmateProcessed.insert({inmate_id: inmate[:id], md5_hash: md5_hash.generate({inmate_id: inmate[:id]})}) unless inmate.nil?
      unless data[:inmate_additional_info].nil?
        data[:inmate_additional_info] = remove_unwanted_chars(data[:inmate_additional_info]).compact
        unless data[:inmate_additional_info].empty?
          data[:inmate_additional_info].merge!(inmate_id: inmate[:id])
          fill_default_fields(data[:inmate_additional_info])
          insert_model(InMarionInmateAdditionalInfo, data[:inmate_additional_info])
        end
      end

      charges_all = []
      unless data[:arrest_info].nil?
        data[:arrest_info].merge!(immate_id: inmate[:id])
        fill_default_fields(data[:arrest_info])
        arrest = insert_model(InMarionArrests, data[:arrest_info])

        unless data[:charges].nil?
          data[:charges].each do |charge|
            cols=[:docker_number,:offense_date,:disposition,:description,:offense_type]
            d = remove_unwanted_chars(charge.slice(*cols)).compact
            unless d.empty?
              d.merge!(arrest_id: arrest[:id])
              fill_default_fields(d)
              charges = insert_model(InMarionCharges, d)
              charges_all.push(charges)
            end
            # addtional
            cols = [:offense_degree]
            d = remove_unwanted_chars(charge.slice(*cols)).compact
            unless d.empty?
              d.merge!(charges_id: charges[:id])
              fill_default_fields(d)
              insert_model(InMarionChargesAdditional, d)
            end
          end
        end
      end
  
      unless data[:inmate_ids_additional].nil?
        data[:inmate_ids_additional] = remove_unwanted_chars(data[:inmate_ids_additional]).compact
        unless data[:inmate_ids_additional].empty?
          data[:inmate_ids_additional].merge!(immate_id: inmate[:id])
          fill_default_fields(data[:inmate_ids_additional])
          insert_model(InMarionInmateIdsAdditional, data[:inmate_ids_additional])
        end
      end
  
      unless data[:holding_facilities].nil?
        data[:holding_facilities] = remove_unwanted_chars(data[:holding_facilities]).compact
        unless data[:holding_facilities].empty?
          fill_default_fields(data[:holding_facilities])
          insert_model(InMarionHoldingFacilities, data[:holding_facilities])
        end
      end
  
      unless data[:court_hearings].nil?
        data[:court_hearings].each do |court_hearing|
          fill_default_fields(court_hearing)
          insert_model(InMarionCourtHearings, court_hearing)
        end
      end
  
      unless data[:bonds].nil?
        data[:bonds].each do |bond|
          cols=[:bond_category,:bond_number,:bond_type,:bond_amount]
          d = remove_unwanted_chars(bond.slice(*cols)).compact
          unless d.empty?
            charge_d = charges_all.select { |ob| ob[:docker_number] == d[:bond_number] }.first
            d.merge!(arrest_id: arrest[:id]) unless arrest.nil?
            d.merge!(charge_id: charge_d[:id]) unless charge_d.nil?
            fill_default_fields(d)
            b = insert_model(InMarionBonds, d)
          end
          # addtional
          cols = [:percent,:posted_by,:additional,:post_date]
          d = remove_unwanted_chars(bond.slice(*cols)).compact
          unless d.empty?
            d.merge!(bonds_id: b[:id])
            
            fill_default_fields(d)
            insert_model(InMarionBondsAdditional, d)
          end
        end
      end
      
      unless data[:inmate_aliases].nil?
        data[:inmate_aliases].each do |inmate_aliase|
          inmate_aliase = remove_unwanted_chars(inmate_aliase).compact
          fill_default_fields(inmate_aliase)
          insert_model(InMarionInmateAliases, inmate_aliase)
        end
      end

    end

  end

  def finish
    # @run_object.finish
    Hamster.logger.debug("finished")
  end

  def insert_model(model, hash)
    record = model.find_by(md5_hash: hash[:md5_hash])
    # replace empty values with nil
    hash.each { |k, v| hash[k] = nil if v.kind_of?(String) && v.empty? }
    if record.nil?
      record = model.create(hash)
    else
      record.update(touched_run_id: hash[:run_id],deleted: 0)
    end

    record
  end

  def remove_unwanted_chars(hash)
    # replace empty values with nil
    hash.each do |k, v|
       if v.kind_of?(String)
        hash[k] = nil if v.empty?
        unless hash[k].nil?
          hash[k] = v.gsub(/nbsp;/i,' ')
          .gsub(/&amp;/i,'&')
          .gsub(/\A[[:space:]]+|[[:space:]]+\z/, '')
          .strip
        end
       end
    end

    hash
  end

  def mark_as_deleted
    InMarionInmates.where(deleted: 0, id: InMarionInmateProcessed.select(:inmate_id)).where.not(touched_run_id: @run_id).update_all(deleted:1)
    InMarionInmateAdditionalInfo.where(deleted: 0, inmate_id: InMarionInmateProcessed.select(:inmate_id)).where.not(touched_run_id: @run_id).update_all(deleted:1)
    InMarionArrests.where(deleted: 0, immate_id: InMarionInmateProcessed.select(:inmate_id)).where.not(touched_run_id: @run_id).update_all(deleted:1)
    InMarionInmateIdsAdditional.where(deleted: 0, immate_id: InMarionInmateProcessed.select(:inmate_id)).where.not(touched_run_id: @run_id).update_all(deleted:1)
    
    InMarionInmateProcessed.connection.truncate(InMarionInmateProcessed.table_name)
  end

  def fill_default_fields(hash)
    md5_hash = MD5Hash.new(columns: hash.keys)
    hash.merge!(run_id: run_id,touched_run_id: run_id)
    hash.merge!(data_source_url: Scraper::DATA_SOURCE_URL,md5_hash: md5_hash.generate(hash))
  end

  def update_current_start(val)
    InMarionInmatesRun.update(run_id,{current_start: val})
    @current_start = val
  end
end
