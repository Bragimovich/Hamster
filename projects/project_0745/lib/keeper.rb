require_relative '../models/new_hampshire_inmates'
require_relative '../models/new_hampshire_arrests'
require_relative '../models/new_hampshire_charges'
require_relative '../models/new_hampshire_court_hearings'
require_relative '../models/new_hampshire_holding_facilities'
require_relative '../models/new_hampshire_inmates_ids'
require_relative '../models/new_hampshire_run'

class Keeper
  def initialize
    super
    @run_id = run.run_id
  end

  attr_reader :run_id

  def status=(new_status)
    run.status = new_status
  end

  def finish
    run.finish
  end
  def store(candidates)
    candidates.each do |info|
      inmates_db     = NewHampshireInmates.find_by(md5_hash: info[:md5_hash], deleted: 0)
      inmates_ids_db = NewHampshireInmatesIds.find_by(md5_hash: info[:md5_hash], deleted: 0)
      charges_db     = HampshireCharges.find_by(md5_hash: info[:md5_hash], deleted: 0)
      arrests_db     = HampshireArrests.find_by(md5_hash: info[:md5_hash], deleted: 0)
      facilities_db  = HoldingFacilities.find_by(md5_hash: info[:md5_hash], deleted: 0)
      hearings_db    = CourtHearings.find_by(md5_hash: info[:md5_hash], deleted: 0)
      if inmates_db.nil?
        NewHampshireInmates.store(full_name: info[:full_name],
                                  age: info[:age],
                                  md5_hash: info[:md5_hash],
                                  run_id: run_id,
                                  touched_run_id: run_id
        )
      else
        if inmates_db[:md5_hash] == info[:md5_hash]
          inmates_db.update(touched_run_id: run_id)
        else
          inmates_db.update(deleted: 1)
          NewHampshireInmates.store(full_name: info[:full_name],
                                    age: info[:age],
                                    md5_hash: info[:md5_hash],
                                    run_id: run_id,
                                    touched_run_id: run_id
          )
        end
      end
      if inmates_ids_db.nil?
        NewHampshireInmatesIds.store(number: info[:inmate_id],
                                     md5_hash: info[:md5_hash],
                                     run_id: run_id,
                                     touched_run_id: run_id
        )
      else
        if inmates_ids_db[:md5_hash] == info[:md5_hash]
          inmates_ids_db.update(touched_run_id: run_id)
        else
          inmates_ids_db.update(deleted: 1)
          NewHampshireInmatesIds.store(number: info[:inmate_id],
                                       md5_hash: info[:md5_hash],
                                       run_id: run_id,
                                       touched_run_id: run_id
          )
        end
      end
      if charges_db.nil?
        HampshireCharges.store(number: info[:term_id],
                               offense_date: info[:offense_date],
                               min_release_date: info[:minimum],
                               max_release_date: info[:maximum],
                               docket_number: info[:docket],
                               md5_hash: info[:md5_hash],
                               run_id: run_id,
                               touched_run_id: run_id
        )
      else
        if charges_db[:md5_hash] == info[:md5_hash]
          charges_db.update(touched_run_id: run_id)
        else
          charges_db.update(deleted: 1)
          HampshireCharges.store(number: info[:term_id],
                                 offense_date: info[:offense_date],
                                 min_release_date: info[:minimum],
                                 max_release_date: info[:maximum],
                                 docket_number: info[:docket],
                                 md5_hash: info[:md5_hash],
                                 run_id: run_id,
                                 touched_run_id: run_id
          )
        end
      end
      if arrests_db.nil?
        HampshireArrests.store(booked_date: info[:booked_date],
                               md5_hash: info[:md5_hash],
                               run_id: run_id,
                               touched_run_id: run_id
        )
      else
        if arrests_db[:md5_hash] == info[:md5_hash]
          arrests_db.update(touched_run_id: run_id)
        else
          arrests_db.update(deleted: 1)
          HampshireArrests.store(booked_date: info[:booked_date],
                                 md5_hash: info[:md5_hash],
                                 run_id: run_id,
                                 touched_run_id: run_id
          )
        end
      end
      if facilities_db.nil?
        HoldingFacilities.store(max_release_date: info[:maximum],
                                facility: info[:facility],
                                md5_hash: info[:md5_hash],
                                run_id: run_id,
                                touched_run_id: run_id
        )
      else
        if facilities_db[:md5_hash] == info[:md5_hash]
          facilities_db.update(touched_run_id: run_id)
        else
          facilities_db.update(deleted: 1)
          HoldingFacilities.store(max_release_date: info[:maximum],
                                  facility: info[:facility],
                                  md5_hash: info[:md5_hash],
                                  run_id: run_id,
                                  touched_run_id: run_id
          )
        end
      end
      if hearings_db.nil?
        CourtHearings.store(case_number: info[:case_id],
                            court_name: info[:court],
                            md5_hash: info[:md5_hash],
                            run_id: run_id,
                            touched_run_id: run_id
        )
      else
        if hearings_db[:md5_hash] == info[:md5_hash]
          hearings_db.update(touched_run_id: run_id)
        else
          hearings_db.update(deleted: 1)
          CourtHearings.store(case_number: info[:case_id],
                              court_name: info[:court],
                              md5_hash: info[:md5_hash],
                              run_id: run_id,
                              touched_run_id: run_id
          )
        end
      end
    end
  end

  private
  def run
    RunId.new(NewHampshireRun)
  end
end
