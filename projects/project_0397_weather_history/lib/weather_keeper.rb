# frozen_string_literal: true

class Keeper < Hamster::Scraper

  attr_reader :first_date, :last_date
  def initialize(loc_id)
    @first_date, @last_date = get_dates(loc_id)
  end

  def get_dates(loc_id)
    dates = []
    WeatherHistory.where(loc_id:loc_id).map { |row| dates.push(row.date) }
    return dates.sort[0], dates.sort[-1]
  end

  def insert_all(data)
    table_sym = :texts
    begin
      DBModels.each_key do |table|
        table_sym = table.to_sym
        insert_data_to_table(data[table_sym], table_sym)
      end
    rescue
      DBModels.each_key do |table_to_delete|
        delete_all(table_to_delete)
        break if table_to_delete == table_sym
      end
    end

  end


  def insert_data_to_table(data, table)
    #begin
    DBModels[table].insert_all(data) if !data.empty?
    # rescue
    #   if data.class==Array
    #     data.each do |leg|
    #       p leg
    #       DBModels[table].insert(leg)
    #     end
    #   end
    # end
  end

  def delete_all(table)
    DBModels[table].where(leg_id:@leg_id).destroy_all
  end

  def self.weather_history_cities(page=0, limit = 100)
    offset = page * limit
    city_ids = []
    WeatherHistoryCities.all().limit(limit).offset(offset).each do |place|
      city_ids.push(place.loc_id)
    end
    city_ids
  end


  def self.get_all_cities(page=0, limit = 100)
    offset = page * limit
    city_names = []
    USAAdministrativeDivisionCounties.where(kind:'city').order(:short_name).limit(limit).offset(offset).each do |place|
      city_names.push("#{place.short_name},#{place.state_name}")
    end
    city_names
  end


end

def existing_text(leg_ids)
  existings = []
  CongressionalLegislationTexts.where(leg_id:leg_ids).map { |row| existings.push(row.leg_id) }
  existings
end