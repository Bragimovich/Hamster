# frozen_string_literal: true

require_relative 'transfer_cases/us_cases'
require_relative 'transfer_cases/transfer_run_id'

module UnexpectedTasks
  module UsCourts
    class TransferCases

      def self.run(**options)
        type = options[:type]
        if type == 'info'
          run_id_object = TransferRunId.new(:info)
          @run_id = run_id_object.run_id
          used_courts = transfer_info
          if !used_courts.nil?
            run_id_object.finish
            mark_deleted_rows(:info, @run_id, used_courts)
          end
        elsif type == 'party'
          run_id_object = TransferRunId.new(:party)
          @run_id = run_id_object.run_id
          used_courts =  lawyers_table
          used_courts = used_courts + transfer_party
          if !used_courts.nil?
            run_id_object.finish
            mark_deleted_rows(:party, @run_id, used_courts)
          end
        elsif type == 'activities'
          run_id_object = TransferRunId.new(:activities)
          @run_id = run_id_object.run_id
          used_courts = transfer_activities
          if !used_courts.nil?
            run_id_object.finish
            mark_deleted_rows(:activities, @run_id, used_courts)
          end
        elsif type == 'act_pdf'
          activities_pdf2
        else
          puts "Doesn't have this type: #{type}"
        end
      end
    end
  end
end

IGNORE_COURTS = [32, 14, 15, 25, 26, 29, 32, 36, 38, 40, 47, 50, 51, 55]

def lawyers_table
  limit = 5000
  page = 0
  used_courts = []
  p "in proccess transfer lawyers to party, run_id:#{@run_id}"
  loop do
    #p page
    offset = limit * page
    parties = []
    md5_hash_array = []
    rows = UsCaseLawyer.where.not(court_id:IGNORE_COURTS).where("created_at>created_at-30").limit(limit).offset(offset)
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

                         :run_id => @run_id, :touched_run_id => @run_id, :deleted => 0
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

                         :run_id => @run_id, :touched_run_id => @run_id, :deleted => 0
                       }

        md5 = PacerMD5.new(data: plaintiff, table: :party)
        plaintiff[:md5_hash] = md5.hash
        md5_hash_array.push(md5.hash)
        parties.push(plaintiff)
        used_courts.push(row.court_id) if !row.court_id.in?(used_courts)
      end

    end

    parties = skip_existed_rows(parties, md5_hash_array, :party)
    put_in_db(parties, :party) unless parties.empty?
    break if rows.to_a.length < limit
    page += 1
  end
  #parties.each { |q| p q }
  used_courts
end


def transfer_party
  limit = 5000
  page = 0
  used_courts = []
  p "in proccess transfer party, run_id:#{@run_id}"
  loop do
    offset = limit * page
    parties = []
    md5_hash_array = []
    rows = UsCaseParty.where.not(court_id:IGNORE_COURTS).where("created_at>created_at-30").limit(limit).offset(offset) #where(updated_date:2days)
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
        :is_lawyer  => row.is_lawyer, :party_description => row.party_description, :party_law_firm => row.law_firm,

        :run_id => @run_id, :touched_run_id => @run_id, :deleted => 0
      }

      md5 = PacerMD5.new(data: case_party, table: :party)
      case_party[:md5_hash] = md5.hash
      md5_hash_array.push(md5.hash)
      used_courts.push(row.court_id) if !row.court_id.in?(used_courts)
      parties.push(case_party)

    end
    #p page
    parties = skip_existed_rows(parties, md5_hash_array, :party)
    put_in_db(parties, :party) unless parties.empty?
    break if rows.to_a.length < limit
    page += 1
  end
  used_courts
end

PACER_COURT_ID = [7, 9, 10, 14, 15, 16, 19, 20, 25, 26, 29, 33, 36, 37, 43, 44, 45, 50, 51, 55]

def transfer_info
  limit = 5000
  page = 0
  used_courts = []
  p "in proccess transfer info, run_id:#{@run_id}"
  loop do
    offset = limit * page
    info_rows = []
    md5_hash_array = []
    rows = UsCaseInfo.where.not(court_id:IGNORE_COURTS).where("created_at>created_at-30").order(:id).limit(limit).offset(offset)
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
        if case_info[:case_name].nil? or !case_info[:case_name].match(' v. ')
          if UsCaseInfoCourts.find_by(case_id:case_info[:case_id])
            case_info[:deleted] = 1
          end
        end
      end

      md5 = PacerMD5.new(data: case_info, table: :info)
      case_info[:md5_hash] = md5.hash
      md5_hash_array.push(md5.hash)
      used_courts.push(row.court_id) if !row.court_id.in?(used_courts)
      info_rows.push(case_info)

    end
    #p page
    info_rows = skip_existed_rows(info_rows, md5_hash_array, :info)
    put_in_db(info_rows, :info) unless info_rows.empty?
    distinct_case_id
    break if rows.to_a.length < limit
    page += 1
  end
  used_courts
end

def distinct_case_id
  UsCaseInfoCourts.where(court_id:PACER_COURT_ID).where(deleted:0).select(:case_id).group(:case_id).having("count(*) > 1").count.each do |case_id, counts|
    UsCaseInfoCourts.where(case_id:case_id).order(:id).order(:last_scrape_date).limit(counts-1).update_all(deleted:1)
  end
end


def transfer_activities
  limit = 5000
  page = 0
  used_courts = []
  p "in proccess transfer activities, run_id:#{@run_id}"

  loop do
    offset = limit * page
    activities = []
    md5_hash_array = []
    rows = UsCaseActivities.where.not(court_id:IGNORE_COURTS).where("created_at>created_at-30").limit(limit).offset(offset)
    rows.each do |row|
      check_columns = [:data_source_url, :activity_decs,
                       :activity_type, :activity_pdf, :file]
      check_columns.each do |column|
        unless check_row(row[column])
          row[column] = nil
        end
      end

      row.pl_gather_task_id=nil if row.pl_gather_task_id<1000 unless row.pl_gather_task_id.nil?

      case_activity = {
        :case_id => row.case_id, :created_by => row.scrape_dev_name,
        :data_source_url => row.data_source_url, :court_id => row.court_id,
        :pl_gather_task_id => row.pl_gather_task_id, :scrape_frequency => row.scrape_frequency,
        :expected_scrape_frequency => row.expected_scrape_frequency,
        :last_scrape_date=> row.last_scrape_date, :next_scrape_date=>row.next_scrape_date,

        :activity_date => row.activity_date, :activity_decs => row.activity_decs, :activity_type => row.activity_type,
        :activity_pdf => row.activity_pdf, :file => row.file, :old_id_temp => row.id,

        :run_id => @run_id, :touched_run_id => @run_id, :deleted => 0
      }

      md5 = PacerMD5.new(data: case_activity, table: :activities)
      case_activity[:md5_hash] = md5.hash
      md5_hash_array.push(md5.hash)
      used_courts.push(row.court_id) if !row.court_id.in?(used_courts)
      activities.push(case_activity)

    end
    #p page
    activities = skip_existed_rows(activities, md5_hash_array, :activities)
    put_in_db(activities, :activities) unless activities.empty?
    break if rows.to_a.length < limit
    page += 1
  end
  used_courts
end

DB_MODELS = {
  party:  UsCasePartyCourts, info: UsCaseInfoCourts, activities: UsCaseActivitiesCourts
}

def skip_existed_rows(rows, md5_hash_array, type)
  existed_md5 = []
  db_model = DB_MODELS[type]
  existed_rows = db_model.where(md5_hash: md5_hash_array)
  existed_rows.map {|row| existed_md5.push(row.md5_hash)}
  existed_rows.update_all(touched_run_id: @run_id, deleted:0)
  new_rows = []
  rows.each { |row| new_rows.push(row) unless row[:md5_hash].in?(existed_md5) }
  new_rows
end

def mark_deleted_rows(type, run_id, courts=nil)
  db_model = DB_MODELS[type]
  db_model.where(court_id:courts).where.not(touched_run_id:run_id).update_all(deleted:1)
end

def put_in_db(rows, type)
  db_model = DB_MODELS[type]
  db_model.insert_all(rows)
end




def check_row(row)
  return if row.nil?
  bad_rows = ['', '-', 'null', 'non', 'none', 'nil', '\n', 'unspecified', '^M']
  !row.downcase.in?(bad_rows)
end




def activities_pdf
  page  = 0
  limit = 5000
  loop do
    offset = page*limit
    activity_pdf = UsCaseActivitiesPDFCourts.where(new_activity_id:nil).limit(limit).offset(offset)
    activity_pdf.each do |row|
      old_id = row.activity_id
      p old_id
      new_id = UsCaseActivitiesCourts.find_by(old_id_temp:old_id)
      next if new_id.nil?
      row.new_activity_id=new_id.id.to_i
      row.save!
    end
    limit+=500
    break if activity_pdf.to_a.length<limit
  end

  # query = "UPDATE us_courts.us_case_activities_pdf SET new_activity_id = (SELECT "

end


def activities_pdf2
  page  = 0
  limit = 5000
  loop do
    p page
    offset = page*limit
    activity_pdf = UsCaseActivitiesPDFCourts.where(new_activity_id:nil).limit(limit).offset(offset)
    activity_pdf.each do |row|
      p row.file
      new_activity_id = UsCaseActivitiesCourts.find_by(file:row.file)
      next if new_activity_id.nil?
      row.new_activity_id = new_activity_id.id
      row.save!
    end
    limit+=500

    break if activity_pdf.to_a.length<limit
  end
end