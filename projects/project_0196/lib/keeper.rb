require_relative '../models/us_dept_ams'

class DBKeeper
  def store(hash)
    begin
      UsDeptAms.insert(hash)
    rescue ActiveRecord::ValueTooLong => e
      puts e
    end
  end
end
  