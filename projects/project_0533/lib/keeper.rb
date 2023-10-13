require_relative '../models/irs_gross_migration'
require_relative '../models/irs_state_inflow'
require_relative '../models/irs_state_outflow'

class Keeper
  def save_csv(model, data)
    data.each {|string| model.store(string) }
  end
end
