# frozen_string_literal: true

require_relative '../models/congress_nomination_errors'
require_relative '../models/congress_nomination_persons'
require_relative '../models/congress_nomination_actions'
require_relative '../models/congress_nomination_nominees'
require_relative '../models/congress_nomination_committee'
require_relative '../models/congress_nomination_departments'


class  Keeper < Hamster::Harvester
  attr_writer :data_hash

  def departments_data
    hash = CongressNominationDepartments.flail { |key| [key, @data_hash[key]] }
    uniq_name = CongressNominationDepartments.find_by(dept_name: @data_hash[:dept_name])
    if uniq_name.nil?
      CongressNominationDepartments.store(hash)
    end
  end

  def committee_data
    hash = CongressNominationCommittee.flail { |key| [key, @data_hash[key]] }
    uniq_name = CongressNominationCommittee.find_by(comm_name: @data_hash[:comm_name])
    if uniq_name.nil?
      CongressNominationCommittee.store(hash)
    end
  end

  def persons_data
    dept_id = CongressNominationDepartments.find_by(dept_name: @data_hash[:dept_name])
    committee_id = CongressNominationCommittee.find_by(comm_name: @data_hash[:comm_name])
    @data_hash.merge!({ dept_id: dept_id.id, committee_id: committee_id.id})
    hash = CongressNominationPersons.flail { |key| [key, @data_hash[key]] }
    hash.merge!({ md5_hash: create_md5_hash(hash)})
    CongressNominationPersons.store(hash)
  end

  def actions_data
    @data_hash[:date_action].size.times do |i|
      latest_action = i.zero? ? 1 : 0
      hash = { nom_id:@data_hash[:nom_id],
                      latest_action: latest_action,
                      action_date: @data_hash[:date_action][i],
                      action_text: @data_hash[:senate_actions][i],
                      urls_in_action: @data_hash[:urls_in_action][i]
                    }
      hash[:md5_hash] = create_md5_hash(hash)
      CongressNominationActions.insert(hash)
    end
  end

  def nominees_data
    if @data_hash[:nominee_text].present? && @data_hash[:nominee_status].present?
      @data_hash[:person_name].size.times do |i|
        hash = { nom_id: @data_hash[:nom_id],
                        nominee_status: @data_hash[:nominee_status][i],
                        nominee_text: @data_hash[:nominee_text],
                        person_name: @data_hash[:person_name][i]
                      }
        hash.merge!({ md5_hash: create_md5_hash(hash)})
        CongressNominationNominees.insert(hash)
      end
    end
  end

  def data_errors(error_hash)
    hash = CongressNominationErrors.flail { |key| [key, error_hash[key]] }
    CongressNominationErrors.store(hash)
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end
end
