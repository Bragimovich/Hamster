# frozen_string_literal: true
require_relative  '../models/milwaukee_county_covid_related_deaths'

class Keeper
  
  def insertion (data)
    MilwaukeeCounty.insert_all(data)
  end

  def mark_deleted
    records = MilwaukeeCounty.where(:deleted => 0).group(:case_number).having("count(*) > 1").pluck(:case_number)
    records.each do |record|
      MilwaukeeCounty.where(:case_number => record).order(id: :desc).offset(1).update_all(:deleted => 1)
    end
  end
end
