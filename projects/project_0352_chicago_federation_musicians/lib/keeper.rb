require_relative '../models/chicago_federation_musicians.rb'
require_relative '../models/chicago_federation_musicians_run.rb'

class Keeper
  def initialize
    @run_object = RunId.new(ChicagoFederationMusiciansRuns)
    @run_id = @run_object.run_id
  end

  def store_chicago_federation_musicians(musicians_data, run_id)
    musicians_data.each do |data|
      begin
        md5_hash = MD5Hash.new(columns: data.keys)
        phone_number_regex = /^\(?[\d]{3}\)?[\s|-]?[\d]{3}-?[\d]{4}$/
        data["phone_number"] = data["phone_number"].split(",").map{|n| n.strip  =~ (phone_number_regex) ? n : ''}.reject(&:empty?).join(',')
        data["phone_number"] = data["phone_number"].blank? ? nil : data["phone_number"]
        md5_hash.generate(data)
        data[:md5_hash] = md5_hash.hash
        data[:touched_run_id] = run_id
        data[:run_id] = run_id
        chicago_federation_musician = Chicago_federation_musicians.find_by(full_name: data['full_name'])
        if chicago_federation_musician.present? && chicago_federation_musician.primary == data['primary'] && chicago_federation_musician.phone_number == data['phone_number'] && chicago_federation_musician.email == data['email']
           chicago_federation_musician.update(data_source_url: data['data_source_url'], md5_hash: data[:md5_hash], run_id: data[:run_id], touched_run_id: data[:touched_run_id])
        else
           Chicago_federation_musicians.create(data)
        end
      rescue Exception=> e
        next
      end
    end
  end

  def finish
    @run_object.finish
  end
end
