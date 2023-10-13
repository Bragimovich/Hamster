# frozen_string_literal: true

require_relative '../models/ny_newyork_bar'
require_relative '../lib/keeper'

class Parser < Hamster::Parser
  def run_csv
    NyNewyorkBar.connection.execute("TRUNCATE TABLE ny_newyork_bar_csv")
    NyNewyorkBar.connection.execute(Keeper.new.load_data)
  end
end
