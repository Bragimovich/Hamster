require_relative '../models/energy_incentives_by_state'

class Keeper
  def store(data)
    data.each {|info| EnergyByState.store(info)}
  end
end
