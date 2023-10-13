
class RunId
  attr_reader :run_id

  DB_MODELS = {:georgia => GeorgiaLawyerStatusRuns, :indiana =>  IndianaLawyerStatusRuns,
               :michigan => MichiganLawyerStatusRuns}

  def initialize(state)
    @db_model = DB_MODELS[state]
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


end