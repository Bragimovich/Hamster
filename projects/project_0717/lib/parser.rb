class Parser < Hamster::Parser

  def parse(pdf)
    clean_info = []
    info_pdfs  = []
    pdf        = PDF::Reader.new(open(pdf)).pages
    pdf_pages  = pdf.join(' ')
    arrestants = pdf_pages.split(/Full .{4,4}/)
    arrestants[1..].each_with_index do |arrestant, i|
      all_dates = arrestant.scan(/\d{1,2}\/\d{1,2}\/\d{1,4}/)
      name      = arrestant.match(/.+(?=Date Arrested)/m).to_s.gsub(/\d/, '').gsub(/\s{1,}/, ' ').gsub(/Count/i, '').gsub(/Page/i, '').gsub('/', '').strip
      if arrestant.match(/\d{1,2}\/\d{1,2}\/\d{1,4}/) #unless
        all_dates.map! do |date|
          revers_date = date.to_s.split('/')
          Date.parse(revers_date[1] + '-' + revers_date[0] + '-' + revers_date[2])
        end
      end
      sex              = (arrestant.match(/\sM\s/) || arrestant.match(/\sF\s/)).to_s
      for_race         = arrestant.match(/.+(?=#{sex})/m).to_s
      race             = (for_race.match(/\sWHITE\s/) || for_race.match(/\sBLACK\s/) || for_race.match(/\sUNKNOWN\s/)).to_s
      for_date_charges = arrestant.gsub(sex.strip, '').gsub(race.to_s, '').gsub(/.+Arrested Location/m, '')
      split_date       = for_date_charges.split(/\d{1,2}\/\d{1,2}\/\d{1,4}/).reject(&:blank?).map(&:strip)
      split_date.each_with_index do |values, i_date|
        values.gsub!(sex, '')
        values.gsub!(race, '')
        build_charge   = []
        build_location = []
        values.split(/\n/).each do |charges_location|
            split_string = charges_location.split(/\s{3,}/).reject(&:blank?)
            split_string.each_with_index do |val, i_val|
            i_val.even? ? build_charge << val : build_location << val
          end
        end
        info                      = {}
        info[:date_arrested]      = all_dates[i_date]
        info[:arrest_location]    = build_location.join(' ').empty? ? nil : build_location.join(' ').squish
        info[:charge]             = build_charge.join(' ').empty? ? nil : build_charge.join(' ').squish
        info[:name]               = name
        sex.empty? ? info[:sex]   = nil : info[:sex] = sex.squish
        race.empty? ? info[:race] = nil : info[:race] = race.squish
        info_pdfs << info
      end
    rescue => e
      Hamster.logger.error(e.full_message)
    end
    info_pdfs.each {|for_record| for_record[:name].count(' ') <= 2 && !for_record[:date_arrested].nil? ? clean_info << for_record : for_record}
    clean_info
    clean_info.each do |inform|
      md5 = MD5Hash.new(columns: inform.keys)
      inform[:md5_hash] = md5.generate(inform)
    end
    clean_info.uniq!
  end
end
