# frozen_string_literal: true

require_relative '../models/illinois_sex_offenders_run'
require_relative '../models/illinois_sex_offenders'
require_relative '../models/Illinois_sex_offenders_crime_details'
require_relative '../models/Illinois_sex_offenders_crimes'

class Keeper
  def initialize
    @run_object = RunId.new(IllinoisSexOffendersRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def save_records(data_hash)
    IllinoisSexOffenders.insert(data_hash)
  end

  def last_inserted_id
    IllinoisSexOffenders.last[:id]
  end

  def fetch_already_inserted_md5
    IllinoisSexOffenders.pluck(:md5_hash).uniq
  end

  def fetch_all_crime_details
    IllinoisSexOffendersCrimeDetails.all.to_a
  end

  def save_crimes(all_crimes)
    IllinoisSexOffendersCrimes.insert_all(all_crimes)
  end

  def fetch_crime_code
    IllinoisSexOffendersCrimeDetails.pluck(:crime_code)
  end

  def save_crimes_details(crimes_array)
    IllinoisSexOffendersCrimeDetails.insert_all(crimes_array)
  end

  def mark_deleted(md5_hash_array)
    md5_hash_array.each do |md5_hash|
      IllinoisSexOffenders.where(md5_hash: md5_hash).first.update(deleted: 1)
    end
  end

  def finish
    @run_object.finish
  end
end
