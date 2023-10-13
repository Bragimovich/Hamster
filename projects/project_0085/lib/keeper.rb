require_relative '../models/irs_state_country_inflow'
require_relative '../models/irs_state_country_outflow'
require_relative '../models/irs_state_country_runs'



class Keeper < Hamster::Parser
  attr_accessor :data_source, :created_by, :year_1, :year_2
  attr_reader :run_id
  def initialize
    super
    run = IRSStateCountryRuns.create
    @run_id = run.id
  end

  def save
    list = peon.list

    list.each do |file|
      tmp_file = peon.copy_and_unzip_temp(file: file)
      case file
      when /inflow/
        save_database(tmp_file, 'inflow')
      when /outflow/
        save_database(tmp_file, 'outflow')
      end
    end
  end

  def save_database(tmp_file, flow)


    case flow
    when 'inflow'
      db_cur = IRSStateCountyInflow
    when 'outflow'
      db_cur = IRSStateCountryOutflow
    end



    db_cur.run_id = run_id
    db_cur.year_1 = year_1
    db_cur.year_2 = year_2
    db_cur.created_by = created_by
    db_cur.data_source = data_source
    db_cur.touched_run_id = run_id
    db_cur.csv_save(tmp_file)
    peon.throw_temps
  end

end
