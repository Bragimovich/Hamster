# frozen_string_literal: true

require_relative '../models/us_cases'


def lawyers_table
  limit = 3000
  page = 0
  loop do
    p page
    offset = limit * page
    parties = []
    md5_hash_array = []
    rows = UsCaseLawyer.limit(limit).offset(offset)
    rows.each do |row|

      check_columns = [:defendant_lawyer_firm, :plantiff_lawyer_firm, :data_source_url,]
      check_columns.each do |column|
        unless check_row(row[column])
          row[column] = nil
        end
      end

      if check_row(row.defendant_lawyer)
        defendant = {
                         :case_id => row.case_number, :created_by => row.scrape_dev_name,
                                    :data_source_url => row.data_source_url, :court_id => row.court_id,
                                    :pl_gather_task_id => row.pl_gather_task_id, :scrape_frequency => row.scrape_frequency,
                                    :expected_scrape_frequency => row.expected_scrape_frequency,
                                    :last_scrape_date=> row.last_scrape_date, :next_scrape_date=>row.next_scrape_date,

                         :party_name => row.defendant_lawyer, :party_law_firm => row.defendant_lawyer_firm,
                         :party_type => "Defendant Lawyer", :is_lawyer => 1,
                       }

        md5 = PacerMD5.new(data: defendant, table: :party)
        defendant[:md5_hash] = md5.hash
        md5_hash_array.push(md5.hash)
        parties.push(defendant)
      end

      if check_row(row.plantiff_lawyer)
        plaintiff = {
                         :case_id => row.case_number, :created_by => row.scrape_dev_name,
                                    :data_source_url => row.data_source_url, :court_id => row.court_id,
                                   :pl_gather_task_id => row.pl_gather_task_id, :scrape_frequency => row.scrape_frequency,
                                   :expected_scrape_frequency => row.expected_scrape_frequency,
                                   :last_scrape_date=> row.last_scrape_date, :next_scrape_date=>row.next_scrape_date,

                         :party_name => row.plantiff_lawyer, :party_law_firm => row.plantiff_lawyer_firm,
                         :party_type => "Plaintiff Lawyer", :is_lawyer => 1,
                       }

        md5 = PacerMD5.new(data: plaintiff, table: :party)
        plaintiff[:md5_hash] = md5.hash
        md5_hash_array.push(md5.hash)
        parties.push(plaintiff)
      end

    end

    parties = skip_existed_rows(parties, md5_hash_array, :party)
    put_in_db(parties, :party) unless parties.empty?
    break if rows.to_a.length < limit
    page += 1
  end
  #parties.each { |q| p q }
end


def transfer_party
  limit = 5000
  page = 0
  loop do
    offset = limit * page
    parties = []
    md5_hash_array = []
    rows = UsCaseParty.limit(limit).offset(offset)
    rows.each do |row|
      check_columns = [:party_name, :party_type, :data_source_url, :party_address,
                       :party_city, :party_description, :law_firm, :party_zip, :party_state, ]
      check_columns.each do |column|
        unless check_row(row[column])
          row[column] = nil
        end
      end
      #next if row.case_name.length>510 unless row.case_name.nil?
      case_party = {
        :case_id => row.case_number, :created_by => row.scrape_dev_name,
        :data_source_url => row.data_source_url, :court_id => row.court_id,
        :pl_gather_task_id => row.pl_gather_task_id, :scrape_frequency => row.scrape_frequency,
        :expected_scrape_frequency => row.expected_scrape_frequency,
        :last_scrape_date=> row.last_scrape_date, :next_scrape_date=>row.next_scrape_date,

        :party_name => row.party_name, :party_type => row.party_type, :party_address => row.party_address ,
        :party_city  => row.party_city, :party_state  => row.party_state , :party_zip  => row.party_zip,
        :is_lawyer  => row.is_lawyer, :party_description => row.party_description,
        :party_law_firm => row.law_firm,
      }

      md5 = PacerMD5.new(data: case_party, table: :party)
      case_party[:md5_hash] = md5.hash
      md5_hash_array.push(md5.hash)

      parties.push(case_party)

    end
    p page
    parties = skip_existed_rows(parties, md5_hash_array, :party)
    put_in_db(parties, :party) unless parties.empty?
    break if rows.to_a.length < limit
    page += 1
  end
end

PACER_COURT_ID = [7, 9, 10, 14, 15, 16, 19, 20, 25, 26, 29, 33, 36, 37, 43, 44, 45, 50, 51, 55]

def transfer_info
  @run_id = 1
  limit = 100
  page = 0
  loop do
    offset = limit * page
    info_rows = []
    md5_hash_array = []
    rows = UsCaseInfo.limit(limit).offset(offset)
    rows.each do |row|
      check_columns = [:disposition_or_status, :judge_name, :data_source_url, :case_description,
                       :status_as_of_date, :case_type, :case_name, ]
      check_columns.each do |column|
        unless check_row(row[column])
          row[column] = nil
        end
      end
      #next if row.case_name.length>510 unless row.case_name.nil?
      case_info = {
        :case_id => row.case_id, :created_by => row.scrape_dev_name,
        :data_source_url => row.data_source_url, :court_id => row.court_id,
        :pl_gather_task_id => row.pl_gather_task_id, :scrape_frequency => row.scrape_frequency,
        :expected_scrape_frequency => row.expected_scrape_frequency,
        :last_scrape_date=> row.last_scrape_date, :next_scrape_date=>row.next_scrape_date,

        :case_name => row.case_name, case_filed_date: row.case_filed_date, :case_type => row.case_type,
        :case_description => row.case_description, :disposition_or_status => row.disposition_or_status,
        :status_as_of_date => row.status_as_of_date, :judge_name => row.judge_name,

        :run_id => @run_id, :touched_run_id => @run_id, :deleted => 0
      }

      if case_info[:court_id].in?(PACER_COURT_ID)
        if !case_info[:case_name].match(' v. ')
          case_info[:deleted] = 1
        end
      end

      md5 = PacerMD5.new(data: case_info, table: :info)
      case_info[:md5_hash] = md5.hash
      md5_hash_array.push(md5.hash)

      info_rows.push(case_info)

    end
    p page
    info_rows = skip_existed_rows(info_rows, md5_hash_array, :info)
    put_in_db(info_rows, :info) unless info_rows.empty?
    distinct_case_id
    break if rows.to_a.length < limit
    page += 1
  end
end

def distinct_case_id
  UsCaseInfoCourts.where(court_id:PACER_COURT_ID).where(deleted:0).select(:case_id).group(:case_id).having("count(*) > 1").count.each do |case_id, counts|
    UsCaseInfoCourts.where(case_id:case_id).order(:id).order(:last_scrape_date).limit(counts-1).update_all(deleted:1)
  end
end



def transfer_activites
  limit = 100
  page = 0
  loop do
    offset = limit * page
    activities = []
    md5_hash_array = []
    rows = UsCaseActivities.limit(limit).offset(offset)
    rows.each do |row|
      check_columns = [:data_source_url, :activity_date, :activity_decs,
                       :activity_type, :activity_pdf, :file]
      check_columns.each do |column|
        unless check_row(row[column])
          row[column] = nil
        end
      end
      #next if row.case_name.length>510 unless row.case_name.nil?
      case_activity = {
        :case_id => row.case_id, :created_by => row.scrape_dev_name,
        :data_source_url => row.data_source_url, :court_id => row.court_id,
        :pl_gather_task_id => row.pl_gather_task_id, :scrape_frequency => row.scrape_frequency,
        :expected_scrape_frequency => row.expected_scrape_frequency,
        :last_scrape_date=> row.last_scrape_date, :next_scrape_date=>row.next_scrape_date,

        :activity_date => row.activity_date, :activity_decs => row.activity_decs, :activity_type => row.activity_type,
        :activity_pdf => row.activity_pdf, :file => row.file,
      }

      md5 = PacerMD5.new(data: case_activity, table: :activities)
      case_activity[:md5_hash] = md5.hash
      md5_hash_array.push(md5.hash)

      activities.push(case_activity)

    end

    activities = skip_existed_rows(activities, md5_hash_array, :activities)
    put_in_db(activities, :activities) unless activities.empty?
    break if rows.to_a.length < limit
    page += 1
  end
end

DB_MODELS = {
  party:  UsCasePartyCourts, info: UsCaseInfoCourts, #activities: UsCaseActivitiesCourts
}

def skip_existed_rows(rows, md5_hash_array, type)
  existed_md5 = []
  db_model = DB_MODELS[type]
  db_model.where(md5_hash: md5_hash_array).map {|row| existed_md5.push(row.md5_hash)}
  #TODO: touched_run_id:new
  new_rows = []
  rows.each { |row| new_rows.push(row) unless row[:md5_hash].in?(existed_md5) }
  new_rows
end



def put_in_db(rows, type)
  db_model = DB_MODELS[type]
  db_model.insert_all(rows)
end




def check_row(row)
  return if row.nil?
  bad_rows = ['', '-', 'null', 'non', 'none', 'nil', '\n', 'unspecified']
  !row.downcase.in?(bad_rows)
end