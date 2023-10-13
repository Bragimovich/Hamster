# frozen_string_literal: true
SC = 338
COA = 461
COURT = {
  :p17027coll3 => SC,
  :p17027coll5 => COA,
  :p17027coll7 => SC,
  :p17027coll8 => COA
}
DESC = %w(judge cita identia descri)

class Helper < Hamster::Parser
  def initialize
    super
  end

  def court_id(api_json)
    court_by_url(api_json["downloadUri"])
  end

  def court_by_url(url)
    collection = url.split('/collection/').last
                    .split('/').first
    COURT[collection.to_sym]
  end

  # def case_id(api_json)
  #   to_hash_of_hashes(api_json["fields"])["relispt"]["value"]&.chomp
  # end

  def to_hash_of_hashes(a_of_h) # array_of_hashes
    a_of_h.map {|el| [el["key"], el]}.to_h
  end

  def activity_desc(h_of_h) # hash_of_hashes
    DESC.map {|key| label_value(h_of_h[key])}.compact.join(" \n ")
  end

  def label_value(hash)
    "#{hash["label"]}: #{hash["value"]&.chomp}" unless hash.nil?
  end
# =================== attorneys_full_info_section ===================
  def party_name(lines)
    lines[0]
  end

  def party_type(lines)
    lines[(@idx.next rescue 0)..].select {|line| line[/ttor|ney\ *for/]}.first
  end

  def party_law_firm(lines)
    lines[2..@idx.pred.pred].join("\n") rescue nil
  end

  def party_address(lines)
    lines[@idx.pred] rescue nil
  end


  def party_city_state_zip(lines)
    lines.each do |line|
      line.sub!('Oregon,', ',Oregon') if line[/\d{5}$/]
      next if line.include?(',')
      line.sub!('OR', ',OR') if line.delete(' ')[/OR\d{5}/]
      line.sub!('WA', ',WA') if line.delete(' ')[/WA\d{5}/]
    end

    @idx = lines.find_index {|line| line.delete(' ')[/[a-zA-Z ]+,([A-Z]{2}|Oregon|Washington|D\.C\.)\d{5}/]}
    despaced_line = (lines[@idx].delete(' ') rescue "")
    zip_offset = despaced_line.index(/\d{5}/)
    {
      party_city:   (lines[@idx].split(',').first               rescue nil),
      party_state:  (despaced_line[0, zip_offset].split(',')[1] rescue nil),
      party_zip:    (despaced_line[zip_offset, 10]              rescue nil)
    }
  end

  def party_description(lines)
    lines[1]
  end
end
