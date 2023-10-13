require_relative '../models/chicago_public_schools_suppliers_payments'
require_relative '../models/chicago_public_schools_suppliers_payments_runs'

class Keeper
  def initialize
    @run_object = RunId.new(ChicagoPublicSchoolsSuppliersPaymentsRuns)
    @run_id = @run_object.run_id
  end
  
  attr_reader :run_id
  
  def finish
    @run_object.finish
  end
end
