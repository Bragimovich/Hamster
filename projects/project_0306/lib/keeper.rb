require_relative '../models/us_tax_exempt_organization'
require_relative '../models/us_tax_exempt_organization_runs'

class Keeper

  def initialize
    @run_object = RunId.new(UsTaxExemptOrganizationRuns)
    @run_id = @run_object.run_id
  end
  attr_reader :run_id

  def save_record(data_array)
    UsTaxExemptOrganization.insert_all(data_array)
  end

  def deletion_mark
    duplicate_records = UsTaxExemptOrganization.where(:deleted => 0).group(:ein).having("count(*) > 1").pluck(:ein)
    duplicate_records.each do |record|
      all_ids = UsTaxExemptOrganization.where(:ein => record).pluck(:id)
      all_ids[0..-2].each do |id|
        UsTaxExemptOrganization.find(id).update(:deleted => 1)
      end
    end
  end

  def finish
    @run_object.finish
  end
end
