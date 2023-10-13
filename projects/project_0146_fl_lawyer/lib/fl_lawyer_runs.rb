
class RunId
  attr_reader :run_id

  def initialize
    @run_id = last_run_id
  end

  def last_run_id
    run_id_line = FloridaLawyerStatusRuns.order(id: :desc).first
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
    run_id_line = FloridaLawyerStatusRuns.new do |i|
      i.id = run_id
    end
    run_id_line.save
  end

  def finish(run_id=@run_id)
    run_id_line = FloridaLawyerStatusRuns.find_by(id:run_id)
    run_id_line.status = 'finish'
    run_id_line.save
  end

end