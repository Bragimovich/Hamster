# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse(source)
    op_layers = JSON.parse(source)["operationalLayers"]
    aggregated_data = op_layers[..-3].map {|state_data| state_data["featureCollection"]["layers"][0]["featureSet"]["features"].map {|el| el["attributes"]}}.flatten
    aggregated_data.map do |el|
      {
        sheriff:  el["Sheriff"],
        county:   el["County"],
        address1: el["Address"]   || el["Address_1"],
        address2: el["Address2"]  || el["Address_2"],
        city:     el["City"],
        state:    el["State"]     || el["State_Province"],
        zip:      el["Zip"],
        phone:    el["Phone"]     || el["WorkPhone"],
        website:  el["Website"]
      }
    end
  end
end
