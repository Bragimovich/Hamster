require_relative '../lib/parser'
require_relative '../lib/keeper'
 class Manager < Hamster::Harvester  
  def initialize
    super
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def parse_store
    pdf_path = @_storehouse_ + "store/06d0f59e291072598040ff8b0579858afcd17c3f.pdf" 
    reader = PDF::Reader.new(pdf_path)
    total_page = ''
    reader.pages.each do |page|
      total_page += page.text + '\n'
    end
    page_info = @parser.get_page_info(total_page)
    @keeper.store_arrests_info(page_info)
    document = reader.pages.map{|page| page.text.scan(/^.+/)}.flatten
    charge_desc = @parser.parse_charge_desc(document)
    result = @keeper.get_name_id
    new_charge_desc = []
    charge_desc.each do |charge|
      name = charge[:name]
      arrest_type = charge[:arrest_type]
      charge2 = charge[:charge]
      charge_description   = charge[:charge_description]
      md5_hash   =  Digest::MD5.hexdigest(arrest_type.to_s + charge2.to_s + charge_description.to_s)
      result.each do |value|
        if charge[:name] == value[0]
          arrest_id = value[1]
          new_charge_desc << { 
            arrest_id: arrest_id,arrest_type: arrest_type,charge: charge2, charge_description: charge_description, deleted: 0, md5_hash: md5_hash }
        end  
      end
    end
    @keeper.store_arrests_chargedesc(new_charge_desc)
    @keeper.finish
    rescue Exception => e
      logger.info(e.full_message)
      Hamster.report(to: 'Mashal Ahmad', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
  end
end    