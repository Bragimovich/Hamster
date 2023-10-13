# frozen_string_literal: true

class TransferRunId
  attr_reader :run_id

  def initialize(type=:info)
    @db_model = run_id_db_model(type)
    @run_id = last_run_id
  end

  def last_run_id
    run_id_line = @db_model.order(id: :desc).first
    if run_id_line.nil?
      run_id = 1
      new_run_id(run_id)
    elsif run_id_line.status == 'finish'
      run_id = run_id_line.id + 1
      new_run_id(run_id)
    else
      run_id = run_id_line.id
    end
    run_id
  end

  def new_run_id(run_id=1)
    run_id_line = @db_model.new do |i|
      i.id = run_id
    end
    run_id_line.save
  end

  def finish(run_id=@run_id)
    run_id_line = @db_model.find_by(id:run_id)
    run_id_line.status = 'finish'
    run_id_line.save
  end

  private

  def run_id_db_model(type)
    model =
      case type
      when :info
        UsCaseInfoCourtsRuns
      when :party
        UsCasePartyCourtsRuns
      when :activities
        UsCaseActivitiesCourtsRuns
      when :judgment
        UsCaseJudgmentCourtsRuns
      when :pdfs_on_aws
        UsCasePdfsOnAwsCourtsRuns
      when :relations_activities_pdf
        UsCasePdfsOnAwsCourtsRuns
      end
    model
  end

end