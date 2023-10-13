# frozen_string_literal: true

class RunManager

  attr_reader :run_id

  def initialize(model)
    @model = model
    @run_id = working_run_id
  end

  def restart
    create_new_id
    @run_id = working_run_id
  end

  def status
    last_run.status
  end

  def status=(status)
    last_run.update(status: status.to_s)
    # status.to_s
  end

  def finish
    last_run.update(status: 'finished')
  end

  private

  def working_run_id
    last = last_run
    if last.nil? || last.status == 'finished'
      create_new_id
      last = last_run
    end
    last.id
  end

  def create_new_id
    @model.create
  end

  def last_run
    @model.last
  end

end

