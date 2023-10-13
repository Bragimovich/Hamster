require_relative '../models/oh_higher_ed_salary'
require_relative '../models/oh_higher_ed_salaries_run'
require_relative '../models/oh_higher_ed_earning'

class Keeper < Hamster::Harvester

  def initialize
    super
    @run_object = RunId.new(OhHigherEdSalariesRun)
    @run_id = @run_object.run_id
  end

  def store_salary(record)
    OhHigherEdSalary.store(record, @run_id)
  end

  def store_earning(record)
    OhHigherEdEarning.store(record, @run_id)
  end
  
  def finish
    @run_object.finish
  end

end