

class DBStore

  def initialize
    super
  end

  def run
    begin

    res = CommonModel.run_update
    rescue StandardError => e
      pp e
    end
    # sql_get_all_tables = "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'crime_perps__step_1' AND TABLE_NAME LIKE '#{prefix}%';"
  end

end
