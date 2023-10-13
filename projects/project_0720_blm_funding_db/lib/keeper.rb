# frozen_string_literal: true
require_relative '../models/blm_funding'
require_relative '../models/blm_funding_runs'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(BlmFundingRuns)
    @run_id = @run_object.run_id
  end

  def store_data(data, model)
    array_hashes = data.is_a?(Array) ? data : [data]

    safe_operation(model) do |model|
      array_hashes.each do |raw_hash|
        hash = add_md5_hash(raw_hash)
        find_dig = model.find_by(contributor: hash[:contributor])
        if find_dig.nil?
          model.insert(hash.merge(run_id: @run_id, touched_run_id: @run_id))
        else
          hash.merge!(touched_run_id: @run_id, deleted: false)
          find_dig.update!(hash)
        end
      end
    end
  end

  def update_recipient(contributor, value)
    find_dig = BlmFunding.find_by(contributor: contributor)
    find_dig.update(recipient: value)
  end

  def add_recipient(contributor, value)
    find_dig = BlmFunding.find_by(contributor: contributor)
    recipients = [] 
    recipients = find_dig[:recipient].split(",") unless find_dig[:recipient].nil?
    find_dig.update(recipient: recipients.push(value).uniq.join(","))
  end

  def add_hq_location(contributor, value)
    find_dig = BlmFunding.find_by(contributor: contributor)
    contributor_hq_locations = [] 
    contributor_hq_locations = find_dig[:contributor_hq_location].split(",") unless find_dig[:contributor_hq_location].nil?
    find_dig.update(contributor_hq_location: contributor_hq_locations.push(value).uniq.join(","))
  end

  def update_location(contributor, value)
    find_dig = BlmFunding.find_by(contributor: contributor)
    find_dig.update(contributor_hq_location: value)
  end

  def update_detail(contributor, value)
    find_dig = BlmFunding.find_by(contributor: contributor)
    find_dig.update(details: value)
  end

  def update_gather_date(contributor)
    find_dig = BlmFunding.find_by(contributor: contributor)
    find_dig.update(gather_year: Date.today.year, gather_month: Date.today.month)
  end

  def update_md5_hash
    BlmFunding.all.each do |record|
      record.update(md5_hash: get_md5_hash(record))
    end
  end

  def add_md5_hash(data_hash)
    data_hash.merge(md5_hash: get_md5_hash(data_hash))
  end

  def get_md5_hash(data_hash)
    data_hash_sliced = data_hash.slice(
      :contributor, 
      :recipient, 
      :contributor_hq_location, 
      :amount, 
      :blm_movement,
      :follow_through,
      :details,
      :source,
      :gather_month,
      :gather_year
    )
    data_string = data_hash_sliced.values.inject('') { |str, val| str += val.to_s }
    md5_hash = Digest::MD5.hexdigest(data_string)
  end

  def change_amount_to_int
    # TODO
    BlmFunding.all.each_with_index do |record, index|
      next if record['amount_ori'].nil? || record['amount_ori'].strip.empty?
      amount = record['amount_ori'].split(".")[0].gsub(",", "").gsub("$", "").to_i

      if amount > 0
        record['amount'] = amount
        record.update(amount: amount, md5_hash: get_md5_hash(record))
      end
    end
  end

  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        sleep 100
        Hamster.report(to: Manager::FRANK_RAO, message: "project-#{Hamster::project_number} Keeper: Reconnecting...")
        model.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end
    retry
    end
  end

  def finish
    @run_object.finish
  end

end
