require_relative '../models/american_express_founds_2019'

class AmericanExpressFounds2019Parser < Hamster::Harvester
  CSV_HEADERS = ['Grant Recipient Name',
                 'Address',
                 'Amount'
  ].freeze

  def initialize
    super
    @peon = Peon.new(storehouse)
    @file_path = "#{storehouse}store/ocr.csv"
  end

  def parse
    csv = CSV.parse(File.read(@file_path), headers: true)
    # uniq_chars = []

    csv.each do |row|
      # puts row[CSV_HEADERS[2]] if row[CSV_HEADERS[2]]&.match?(/[ $,.IOSalos]/)
      # uniq_chars << row[CSV_HEADERS[2]] if row[CSV_HEADERS[2]]&.match?(/[a]/)
      # uniq_chars << row[CSV_HEADERS[2]] if row[CSV_HEADERS[2]][1..-1]&.match?(/[ $,.IOSalos]/)
      # uniq_chars << row[CSV_HEADERS[2]]&.split(//)&.uniq

      # uniq_chars.flatten!
      # uniq_chars.uniq!
      begin
        if row[CSV_HEADERS[2]].nil?
          amount = nil
        else
          amount = row[CSV_HEADERS[2]][1..-1]&.gsub(/[,. ]/, '')&.gsub(/o/i, '0')&.gsub(/[il]/i, '1')&.gsub(/s/i, '5')&.gsub(/a/i, '4')&.sub(' ', '.')
          amount = amount.insert(-3, '.') if amount.length > 2
        end

        AmericanExpressFounds2019.create(
        grant_recipient_name: row[CSV_HEADERS[0]],
        address: row[CSV_HEADERS[1]],
        amount: amount,
        raw_amount: row[CSV_HEADERS[2]])

        # t = AmericanExpressFounds2019.create(
        # t.grant_recipient_name = row[CSV_HEADERS[0]]
        # t.address = row[CSV_HEADERS[1]]
        # t.amount = row[CSV_HEADERS[2]].sub(',', '').gsub(/o/i, '0').sub(' ', '.'))
        # DatabaseManager.save_item(t)
      rescue ActiveRecord::ActiveRecordError => e
        raise
      end
    end
    # puts uniq_chars.compact.sort.inspect
  end

  private

  def format_zip(zip)
    # puts cell.inspect
    if zip.size == 9
      "#{zip[0..4]}-#{zip[-4..-1]}"
    else
      zip
    end
  end
end



