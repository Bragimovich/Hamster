# frozen_string_literal: true

class WSCCRunId
  attr_reader :run_id

  def initialize
    @run_id = last_run_id
  end

  def last_run_id
    run_id_line = WsccRuns.order(run_id: :desc).first
    if run_id_line.nil?
      run_id = 1
      new_run_id(run_id)
    elsif run_id_line.status == 'finish'
      run_id = run_id_line.run_id + 1
      new_run_id(run_id)
    else
      run_id = run_id_line.run_id
    end
    run_id
  end

  def new_run_id(run_id=1)
    run_id_line = WsccRuns.new do |i|
      i.run_id = run_id
    end
    run_id_line.save
  end

  def finish(run_id=@run_id)
    run_id_line = WsccRuns.find_by(run_id:run_id)
    run_id_line.status = 'finish'
    run_id_line.save
  end

end