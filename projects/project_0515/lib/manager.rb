require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  BASE_URL = "https://data.cdc.gov"
  def initialize
    super
    @scraper = Scraper.new
    @keeper = Keeper.new
  end

  # there will be no parser in this case becuase api returns the data in json format so direcly saving it in db
  def download_and_store
    limit = 14
    offset = 0
    while true
      url = BASE_URL + "/api/id/muzy-jte6.json?" + query_params(limit,offset)
      response, status = @scraper.get_request(url,nil)
      doc = response.body
      # remove new lines from doc
      doc.gsub!("\n","")
      # convert doc string to hash
      string_to_array_hash = eval(doc)
      break if string_to_array_hash == []
      string_to_array_hash.each do |hash|
        # change the hash key names to match the db column names
        hash1 = hash.map{|k,v| [key_pair_mapping[k.to_sym],v]}.to_h
        hash1['data_source_url'] = BASE_URL
        @keeper.store(hash1)
        hash2 = hash.map{|k,v| [key_pair_mapping_for_devs[k.to_sym],v]}.to_h
        hash2['data_source_url'] = BASE_URL
        @keeper.store_for_devs(hash2)
      end
      offset += limit
    end
    @keeper.delete_old_records
    @keeper.finish
  end

  private

  def query_params(limit,offset)
    "$select=`data_as_of`,`jurisdiction_of_occurrence`,`mmwryear`,`mmwrweek`,`week_ending_date`,`all_cause`,`natural_cause`,`septicemia_a40_a41`,`malignant_neoplasms_c00_c97`,`diabetes_mellitus_e10_e14`,`alzheimer_disease_g30`,`influenza_and_pneumonia_j09_j18`,`chronic_lower_respiratory`,`other_diseases_of_respiratory`,`nephritis_nephrotic_syndrome`,`symptoms_signs_and_abnormal`,`diseases_of_heart_i00_i09`,`cerebrovascular_diseases`,`covid_19_u071_multiple_cause_of_death`,`covid_19_u071_underlying_cause_of_death`,`flag_allcause`,`flag_natcause`,`flag_sept`,`flag_neopl`,`flag_diab`,`flag_alz`,`flag_inflpn`,`flag_clrd`,`flag_otherresp`,`flag_nephr`,`flag_otherunk`,`flag_hd`,`flag_stroke`,`flag_cov19mcod`,`flag_cov19ucod`&$order=`:id`+ASC&$limit=#{limit}&$offset=#{offset}"
  end

  def key_pair_mapping
    {
      :data_as_of => "data_as_of",
      :jurisdiction_of_occurrence => "jurisdiction_of_occurrence",
      :mmwryear => "mm_wr_year",
      :mmwrweek => "mm_wr_week",
      :week_ending_date => "week_ending_date",
      :all_cause => "all_cause",
      :natural_cause => "natural_cause",
      :septicemia_a40_a41 => "septicemia_a40_a41",
      :malignant_neoplasms_c00_c97 => "malignant_neoplasms_c00_c97",
      :diabetes_mellitus_e10_e14 => "diabetes_mellitus_e10_e14",
      :alzheimer_disease_g30 => "alzheimer_disease_g30",
      :influenza_and_pneumonia_j09_j18 => "influenza_and_pneumonia_j09_j18",
      :chronic_lower_respiratory => "chronic_lower_respiratory",
      :other_diseases_of_respiratory => "other_diseases_of_respiratory",
      :nephritis_nephrotic_syndrome => "nephritis_nephrotic_syndrome",
      :symptoms_signs_and_abnormal => "symptoms_signs_and_abnormal",
      :diseases_of_heart_i00_i09 => "diseases_of_heart_i00_i09",
      :cerebrovascular_diseases => "cerebrovascular_diseases",
      :covid_19_u071_multiple_cause_of_death => "covid_19_u071_multiple_cause_of_death",
      :covid_19_u071_underlying_cause_of_death => "covid_19_u071_underlying_cause_of_death"      
    }
  end

  def key_pair_mapping_for_devs
    {
      :data_as_of => "date of analysis",
      :jurisdiction_of_occurrence => "Jurisdiction of Occurrence",
      :mmwryear => "Morbidity and Mortality Weekly Report Year",
      :mmwrweek => "Morbidity and Mortality Weekly Report Week",
      :week_ending_date => "week ending date",
      :all_cause => "all causes",
      :natural_cause => "natural causes",
      :septicemia_a40_a41 => "sepsis",
      :malignant_neoplasms_c00_c97 => "cancer",
      :diabetes_mellitus_e10_e14 => "diabetes",
      :alzheimer_disease_g30 => "Alzheimers disease",
      :influenza_and_pneumonia_j09_j18 => "influenza and pneumonia",
      :chronic_lower_respiratory => "chronic lower respiratory diseases",
      :other_diseases_of_respiratory => "respiratory diseases",
      :nephritis_nephrotic_syndrome => "kidney diseases",
      :symptoms_signs_and_abnormal => "unknown causes of death",
      :diseases_of_heart_i00_i09 => "heart diseases",
      :cerebrovascular_diseases => "stroke or cerebrovascular diseases",
      :covid_19_u071_multiple_cause_of_death => "existing conditions worsened by COVID-19",
      :covid_19_u071_underlying_cause_of_death => "COVID-19"
    }
  end
end
