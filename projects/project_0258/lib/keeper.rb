require_relative '../models/hawaii_fire_department_chief_annual_report'
require_relative '../models/hawaii_fire_department_chief_monthly_report'
require_relative '../models/hawaii_fire_department_chief_runs'

class Keeper
  def initialize
    @run_object = RunId.new(HawaiiFireDepartmentChiefRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def annual_insertion(record)
    HFDCAnnualReports.insert(record)
  end

  def monthly_insertion(record)
    HFDCMonthlyReports.insert(record)
  end

  def already_inserted_records
    monthly = HFDCMonthlyReports.pluck(:md5_hash)
    yearly = HFDCAnnualReports.pluck(:md5_hash)
    monthly + yearly
  end

  def mark_deleted
    records = HFDCMonthlyReports.where(:deleted => 0).group(:src_pdf_link).having("count(*) > 1")
    records.each do |record|
      record.update(:deleted => 1)
    end

    records = HFDCAnnualReports.where(:deleted => 0).group(:src_pdf_link).having("count(*) > 1")
    records.each do |record|
      record.update(:deleted => 1)
    end
  end

  def finish
    @run_object.finish
  end
end
