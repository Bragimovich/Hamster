# frozen_string_literal: true


class Embassy < Hamster::Scraper

  def initialize(update=0)
    super
    make_several_configs
    get_all_embassy
  end

  ALL_EMBASSY = %w[gh et dz kz jo nl tr tm py gr iq th lb rs bz ch lb kg co sk bb be hu ar eg ma md lk bj jo tz bd dj
                   gy ec cu fi vn zw pk id il za af sd rw jm cd my kw ng ga mw pe si tg uk ao es ni bh ph lr uy ca ru
                   om it bs in ne cy bf fr kh cz cv xk ht mm is lv br sa cr sv cl do ba kr mk bg se fj au ee uz ge hn
                   tn mn at la lt pl am hr sl in al]

  def get_all_embassy
    ALL_EMBASSY.each do |emb|
      get_embassy(emb)
    end
  end


  def get_embassy(emb)
    scr = Hamster::Scraper.new()
    scr.robohamster("../configs/us_embassy/#{emb}.yml")

  end


  def make_several_configs
    file = "../configs/us_embassy.yml"

    config_file = ""
    File.open(file).readlines.map { |row| config_file+=row }

    ALL_EMBASSY.each do |emb|

      new_config = config_file.gsub('<<embassy_abbr>>', emb)

      File.open("../configs/us_embassy/#{emb}.yml", 'w') { |file| file.write(new_config) }
    end

  end

end
