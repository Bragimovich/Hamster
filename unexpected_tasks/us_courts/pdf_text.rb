require_relative 'pdf_text/pdf_models'


module UnexpectedTasks
  module UsCourts
    class PdfText
      def self.run(**options)
        @filepath = '../pdf_files'
        @limit = options[:limit] || 1000

        Dir.mkdir @filepath unless File.exists?(@filepath)
        if options[:court]=='saac'
          self.pdf_from_aws_saac
        else
          self.pdf_from_aws
          self.pdf_from_aws_saac
        end
      end


      def self.pdf_from_aws(court_id=nil)
        page = 0
        loop do
          Hamster.logger.debug page
          offset = @limit * page
          pdfs_db = UsCasePdfOnAws.where('aws__html_link is null').where('aws_link is not null').where(done:0).order(:id).limit(@limit).offset(offset) #
          report_text = []
          pdf_links = pdfs_db.map { |row| row.aws_link.gsub(' ', '%20') }
          existing_links = self.get_existing_links(pdf_links)

          #existing_links = self.get_existing_links_from_case_ids(pdf_links)
          pdfs_db.each do |pdf_row|
            file_link = pdf_row.aws_link
            if file_link.in?(existing_links)
              pdf_row.update(done:1)
              next
            end
            UsCaseReportText.insert({
                                          court_id: pdf_row.court_id,
                                          case_id:  pdf_row.case_id.strip,
                                          aws_link: pdf_row.aws_link
                                        })

            pdf_link = file_link.gsub(' ', '%20').gsub('"', '%22')
            pdf_file = Faraday.get(pdf_link).body
            filename = file_link.split('/')[-1]
            path_file = "#{@filepath}/#{filename.gsub(' ','%20')}"
            File.open(path_file, 'wb') { |fp| fp.write(pdf_file) }

            begin
              reader = PDF::Reader.new(path_file)

              text_pdf = ''
              reader.pages.each do |page|
                text_pdf += page.text
              end
              text_ocr = nil
              ocr = 0
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
                                                                             text_pdf: text_pdf,
                                                                             text_ocr: text_ocr
                                                                           })
              pdf_row.update(done:1)
            rescue => e
              Hamster.log "Error: #{e}, path: #{path_file}"
            ensure
              File.delete(path_file) if File.exist?(path_file)
            end
          end
          page += 1
          break if pdfs_db.to_a.length<@limit
          UsCasePdfOnAws.connection.reconnect!
        end
      end


      def self.get_existing_links(pdf_links)
        UsCaseReportText.where(aws_link:pdf_links).map { |row| row.aws_link }
      end


      def self.pdf_from_aws_saac(court_id=nil)
        limit = @limit
        page = 0

        loop do
          Hamster.logger.debug page
          offset = limit * page
          pdfs_db = UsSAACCasePdfOnAws.where(done:0).order(id: :desc).limit(limit).offset(offset) #.where("id not in (SELECT pdf_on_aws_id FROM us_courts_analysis.us_saac_case_report_text)"
          report_text = []
          pdf_links = pdfs_db.map { |row| row.aws_link }
          existing_links = self.get_existing_links_saac(pdf_links)
          pdfs_db.each do |pdf_row|
            file_link = pdf_row.aws_link
            if file_link.in?(existing_links)
              pdf_row.update(done:1)
              next
            end
            UsSAACCaseReportText.insert({
                                          court_id: pdf_row.court_id,
                                          case_id:   pdf_row.case_id,
                                          aws_link:  pdf_row.aws_link
                                        })

            pdf_link = file_link.gsub(' ', '%20').gsub('"', '%22')
            pdf_file = Faraday.get(pdf_link).body
            filename = file_link.split('/')[-1]
            path_file = "#{@filepath}/#{filename.gsub(' ','%20')}"
            File.open(path_file, 'wb') { |fp| fp.write(pdf_file) }

            begin
                reader = PDF::Reader.new(path_file)
                text_pdf = ''
                reader.pages.each do |page|
                  text_pdf += page.text
                end

                text_ocr = ''
                if text_pdf.length<100
                  images = PDFToImage.open(path_file)
                  images.each do |img|
                    filename = "#{path_file}#{img.page}.jpg"
                    img.save(filename)
                    image = RTesseract.new(filename)
                    text_ocr += image.to_s
                    File.delete(filename) if File.exist?(path_file)
                  end
                  ocr = 1
                end

                UsSAACCaseReportText.where(aws_link:pdf_row.aws_link).update({
                                   pdf_on_aws_id: pdf_row.id,
                                   pdf_on_aws_md5_hash: pdf_row.md5_hash,
                                   text_pdf: text_pdf,
                                   text_ocr: text_ocr,
                                   ocr: ocr,
                                         })
                pdf_row.update(done:1)
            rescue => e
              Hamster.logger.error "Error: #{e}, path: #{path_file}"
            ensure
              File.delete(path_file) if File.exist?(path_file)
            end
          end
          page += 1
          break if pdfs_db.to_a.length<limit
          UsSAACCasePdfOnAws.connection.reconnect!
        end
      end


      def self.get_existing_links_saac(pdf_links)
        UsSAACCaseReportText.where(aws_link:pdf_links).map { |row| row.aws_link }
      end


    end
  end
end