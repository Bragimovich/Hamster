require_relative '../models/runs'
require_relative '../models/exim'


class Keeper

  def initialize
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id
  end

  def existed_article(link)
    Exim.where(link:link).first
  end

  def save_data(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    Exim.insert(data)
  end

  def finish
    @run_object.finish
  end

end