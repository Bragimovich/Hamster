require_relative 'pdf_text/pdf_models'


module UnexpectedTasks
  module UsCourts
    class HtmlText
      def self.run(**options)
        @filepath = '../pdf_files'
        @limit = options[:limit] || 1000

        Dir.mkdir @filepath unless File.exists?(@filepath)
        # if options[:court]=='saac'
        #   self.pdf_from_aws_saac
        # else
          self.html_from_aws
          # self.pdf_from_aws_saac
        # end


      end

      def self.html_from_aws(court_id=nil)
        page = 0
        loop do
          p page
          offset = @limit * page
          pdfs_db = UsCasePdfOnAws.where('aws__html_link is not null').order(:id).limit(@limit).offset(offset) #

          pdf_links = pdfs_db.map { |row| row.aws_link.gsub(' ', '%20') }
          existing_links = self.get_existing_links(pdf_links)

          #existing_links = self.get_existing_links_from_case_ids(pdf_links)
          pdfs_db.each do |pdf_row|
            next if existing_links.include?(pdf_row.aws_link)
            UsCaseReportText.insert({
                                      court_id: pdf_row.court_id,
                                      case_id:  pdf_row.case_id.strip,
                                      aws_link: pdf_row.aws_link
                                    })

            file_link = pdf_row.aws__html_link.gsub(' ', '%20')

            html_file = Faraday.get(file_link).body
            # filename = file_link.split('/')[-1]
            # path_file = "#{@filepath}/#{filename.gsub(' ','%20')}"
            # File.open(path_file, 'wb') { |fp| fp.write(pdf_file) }

            #begin
            next if html_file.nil?
            html_text = self.text_from_html(html_file)
              #if keywords_hash.empty?
              # text_ocr = ''
              # images = PDFToImage.open(path_file)
              # images.each do |img|
              #   filename = "#{path_file}#{img.page}.jpg"
              #   img.save(filename)
              #   image = RTesseract.new(filename)
              #   text_ocr += image.to_s
              #   File.delete(filename) if File.exist?(path_file)
              # end
              # ocr = 1
              #end


              UsCaseReportText.where(aws_link:pdf_row.aws_link).update({
                                                                         pdf_on_aws_id: pdf_row.id,
                                                                         pdf_on_aws_md5_hash: pdf_row.md5_hash,
                                                                         text_pdf: html_text,
                                                                         from_html: 1,
                                                                       })
            # rescue => e
            #   p e
            #   p path_file
            # ensure
            #   File.delete(path_file) if File.exist?(path_file)
            # end
          end
          page += 1
          break if pdfs_db.to_a.length<@limit
        end
      end


      def self.get_existing_links(pdf_links)
        UsCaseReportText.where(aws_link:pdf_links).map { |row| row.aws_link }
      end

      def self.text_from_html(html_file)
        html_file_2 = html_file.split('</head>')[-1]
        html_file = html_file_2 if !html_file_2.nil?
        html_file_2 = html_file.split('<footer>')[0]
        html_file = html_file_2 if !html_file_2.nil?

        html_file = html_file.gsub('><', '> <')
        doc = Nokogiri::HTML(html_file)
        doc.css('script').remove
        doc.css('style').remove
        doc.content
      end

    end
  end
end