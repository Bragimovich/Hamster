require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  COURT_ID = 320
  attr_reader :keeper, :run_id, :pdf_path 
  
  def initialize(**params)
    super
    @keeper                 = Keeper.new
    @run_id                 = @keeper.run_id
    @already_inserted_pdf   = @keeper.get_inserted_pdf
    @pdf_path               = create_subfolder("#{run_id}", full_path: true)
    @scraper                = Scraper.new
    @parser                 = Parser.new
    @s3                     = AwsS3.new(bucket_key = :us_court)
  end

  def start
    Hamster.report(to: 'U02JPKC1KSN', message: "0638 Download Started")
    pages = []
    last_page = @scraper.opinions_page('opinions.html') 
    pages << last_page
    @parser.html = last_page
    @parser.older_opinions_pages { |link| pages << @scraper.opinions_page(link) } 

    pages.compact.each do |page|
      @parser.html = page
      pdf_links = @parser.list_pdf_names
      pdf_links.each do |pdf_link|
        pdf_url = if pdf_link.match?(/\//)
                    "https://www.courts.maine.gov/courts/sjc/#{pdf_link}"
                  else
                    "https://www.courts.maine.gov/courts/sjc/lawcourt/20#{pdf_link[/\d{2}/]}/#{pdf_link}"  
                  end

        begin
          fetch_pdf_data(pdf_url)
        rescue => e
          Hamster.report(to: 'U02JPKC1KSN', message: "#{e.message}")
          Hamster.logger.error("#{e.message}")
          next
        end
        
        @parser.pdf_content(@pdf_content, @pdf_content_img)
        case_ids = @parser.case_ids  
         
        case_ids.each do |case_id|
          Hamster.logger.info("Store: #{case_id}")
          @parser.case_id = case_id
          @parser.data_source_url = pdf_url
  
          case_party_arr  = @parser.case_party
          case_activities = @parser.case_activities
          case_info_hash  = @parser.case_info
          aws_link = @already_inserted_pdf.find { |entry| entry[0] == case_id && entry[1] == pdf_url }&.last
          aws_link ||= save_to_aws(url: pdf_url, case_id: case_id)
          aws_hash = @parser.case_aws_hash(pdf_url, aws_link)

          keeper.store_info_hash(case_info_hash, MeScCaseInfo)
          keeper.store_data(case_activities, MeScCaseActivities)

          activity_decided = case_activities.find { |hash| hash[:file].present? }

          if activity_decided
            md5_activity = keeper.get_activity_md5_for(case_id, activity_decided[:file], activity_decided[:activity_type], activity_decided[:activity_date])

            relations_hash = @parser.add_md5_hash(
              {
              case_activities_md5: md5_activity,
              case_pdf_on_aws_md5: aws_hash[:md5_hash]
              }
            )

            keeper.store_data(relations_hash, MeScCaseRelationsActivityPdf)
          end

          keeper.store_data(case_party_arr, MeScCaseParty)
          keeper.store_data(aws_hash, MeScCasePdfsOnAws)
        end   
      end
    end
    
    after_store
  end

  private

  def fetch_pdf_data(url)
    File.delete(*Dir.glob("#{@pdf_path}/*.{jpg,pdf}"))

    file_name = url[/[^\/]+$/]
    pdf_storage_path = "#{@pdf_path}/#{file_name}"
    pdf_file = @scraper.download_pdf(url)
    raise "Pdf url doesnt available!\n#{url}" unless pdf_file

    File.open(pdf_storage_path, "wb") do |f|
      f.write(pdf_file)
    end

    Hamster.logger.info "___PDF SAVED: #{file_name}___"
    extract_pdf(pdf_storage_path)
    extract_pdf_with_img(pdf_storage_path)
    @raw_pdf_body = pdf_file
    File.delete(pdf_storage_path) if File.exist?(pdf_storage_path)
  end

  def extract_pdf(path)
    @pdf_content = PDF::Reader.new(path) rescue nil
  end

  def extract_pdf_with_img(path)
    images = PDFToImage.open path
    @pdf_content_img = ""

    images.reverse.each_with_index do |img, i| 
      filename = "#{path}#{img.page}.jpg"
      img.save(filename)
      image = RTesseract.new(filename)
      @pdf_content_img = image.to_s + @pdf_content_img
      File.delete(filename) if File.exist?(filename)
      break if @pdf_content_img.gsub(/\n ?\d*\n{2,}(?! )/, "\n"*5).match?(/(The(\n|\t|\s)*?entry(\n|\t|\s)*?is:?(\n|\t|\d|\s){1,})/m) || i > 5
    end
  end

  def save_to_aws(**params)
    file_name = params[:url][/[^\/]+$/]
    key = "us_courts_expansion/#{COURT_ID}/#{params[:case_id]}_opinion/#{file_name}"
    @s3.find_files_in_s3(key).empty? ? @s3.put_file(@raw_pdf_body, key, metadata={url: params[:url]}) : "https://court-cases-activities.s3.amazonaws.com/#{key}"
  end

  def create_subfolder(subfolder, full_path: false)
    path = "#{storehouse}store/#{subfolder}"
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
    full_path ? path : subfolder
  end

  def after_store
    models = [
      MeScCaseInfo, MeScCaseParty, MeScCaseActivities, 
      MeScCasePdfsOnAws, MeScCaseRelationsActivityPdf
    ]

    File.delete(*Dir.glob("#{@pdf_path}/*"))
    keeper.update_delete_status(*models)
    keeper.finish

    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number} => Store finished")
    Hamster.logger.info("___________STORE FINISHED____________")
  end
end
