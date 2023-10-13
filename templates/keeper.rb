# require model files here
require_relative '../models/xxxx_runs'
class Keeper < Hamster::Keeper
  attr_reader :run_id

  def initialize
    super
    @run_object = RunId.new(RunModelName)
    @run_id = @run_object.run_id
  end

  def store(hash_data)
    # write store logic here
  end

  def finish
    @run_object.finish
  end
end
