require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester
  def initialize
    super
    @parser  = Parser.new
    @keeper  = Keeper.new
    @scraper = Scraper.new
  end

  def download
    main_url   = 'https://www.oig.dol.gov/newsroomcurrent.htm'
    main_page = scraper.connect_to(main_url)
    save_file("#{keeper.run_id}",main_page.body,"Outer_page")
    links = parser.get_inner_links(main_page.body)
    download_files(links)
  end

  def store
    db_states = keeper.fetch_states.map{|e| e[0]}
    outer_page = peon.give(subfolder: "#{keeper.run_id}", file: "Outer_page")
    links    = parser.get_inner_links(outer_page)
    already_inserted_links = keeper.fetch_db_inserted_links
    links.each do |link|
      next if already_inserted_links.include? link
      file_md5        = Digest::MD5.hexdigest link
      file_name       = file_md5 + '.pdf'
      file_path       = "#{storehouse}store/#{keeper.run_id}/pdfs/#{file_name}"
      data_hash       = parser.links_data(outer_page,link,"#{keeper.run_id}",file_path, db_states)
      keeper.insert_record(data_hash)
    end
    keeper.finish
  end

  private
  attr_accessor :keeper, :parser, :scraper

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

  def download_files(links)
    already_inserted_links = keeper.fetch_db_inserted_links
    links.each do |link|
      next if already_inserted_links.include? link
      file_name = Digest::MD5.hexdigest link
      pdf_response = scraper.connect_to(link)
      next unless pdf_response.status == 200
      save_pdf(pdf_response.body, file_name)
    end
  end

  def save_pdf(pdf, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}/pdfs"
    pdf_storage_path = "#{storehouse}store/#{keeper.run_id}/pdfs/#{file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(pdf)
    end
  end

end
