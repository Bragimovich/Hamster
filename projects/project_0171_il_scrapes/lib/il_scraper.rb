# frozen_string_literal: true
require 'roo'
require 'roo-xls'

class Scraper < Hamster::Scraper

  def initialize(**args)
    super
    # run_id_class = RunId.new()
    # @run_id = run_id_class.run_id
    gathering() if args[:download]
    store() if args[:store]
    update() if args[:update]

    # deleted_for_not_equal_run_id(@run_id)
    # run_id_class.finish
  end


  def gathering(update=0)
    peon = Peon.new(storehouse)

    cobble = Dasher.new(:using=>:cobble) #, ssl_verify:false , :redirect=>true


    parser = Parser.new()

    url_main = "https://www2.illinois.gov/rev/localgovernments/disbursements/salesrelated/Pages/Monthly-Archive.aspx"

    page_list_xls = cobble.get(url_main)

    links_on_xls = parser.parse_html_page(page_list_xls)


        # if general_lawyers_array.empty?
        #   if trying>3
        #     mess = "\nEmpty: page#{page}|#{url_main}"
        #     log mess, :red
        #     Hamster.report(to:'Maxim Gushchin', message: mess, use: :slack)
        #     exit 0
        #   end
        #   #sleep(45**trying)
        #   trying+=1
        #   redo
        # end

      q=0

    links_on_xls.each do |month_date, url_on_xls|
        xls_file = cobble.get(url_on_xls)
        format_file = url_on_xls.split('.')[-1].downcase
        File.write("#{storehouse}#{month_date}.#{format_file}", xls_file)
        break if q>3 and update!=0
        q+=1
    end
    p "#{q} files were saved"
  end

  def store
    all_date_location = get_date_in_db()
    target_path = "#{storehouse}trash/"
    Dir["#{storehouse}*.xls*"].each do |path_to_file|
      filename = path_to_file.split('/')[-1]
      p filename
      all_data =
        case filename.split('.')[-1]
          when 'xlsx'
            parse_xlsx_file(path_to_file)
          when 'xls'
            parse_xls_file(path_to_file)
          end


      if !all_data[:by_location].empty?
        unless all_data[:by_location][0][:voucher_date].in?(all_date_location)
          insert_all_by_location(all_data[:by_location])
        end
      end

      if !all_data[:tax_type_totals].empty?
        unless all_data[:tax_type_totals][0][:voucher_date].in?(all_date_location)
          insert_all_tax_type_totals(all_data[:tax_type_totals])
        end
      end
      File.rename path_to_file, target_path+filename
    end

  end


  def update
    gathering(update=1)
    store
  end


end