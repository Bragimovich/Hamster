class Parser < Hamster::Parser
  def initialize
    super
    @db = Mysql2::Client.new(Storage[host: :db02, db: :limparanoia])
  end

  def parse(spreadsheet)
    data = []
    rows = spreadsheet.worksheets[1].rows
    keys = rows[0].map {|column| column.underscore.gsub(/\s/, '_').gsub(/\W/, '')}
    info = rows[1..-1]
    info.each do |one_row|
      for_record = {}
      one_row.each_with_index do |entry, i|
        for_record[keys[i].to_sym] = entry.squish.force_encoding('iso-8859-1')
      end
      md5 = MD5Hash.new(columns: for_record.keys)
      for_record[:md5_hash] = md5.generate(for_record)
      data << for_record
    end
    data
  end
end
