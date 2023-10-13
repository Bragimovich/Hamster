# frozen_string_literal: true

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[bar_number name law_firm_name type registration_status date_admitted]
  columns.each do |key|
    if news_hash[key].nil?
      all_values_str = all_values_str + news_hash[key.to_s].to_s
    else
      all_values_str = all_values_str + news_hash[key].to_s
    end
  end
  Digest::MD5.hexdigest all_values_str
end



class Scraper < Hamster::Scraper

  def initialize(update=0)
    super
    run_id_class = RunId.new()
    @run_id = run_id_class.run_id
    scrape_answer = gathering(update)
    if scrape_answer == 1
      deleted_for_not_equal_run_id(@run_id)
      run_id_class.finish
    end
  end


  def gathering(update)
    limit = 100
    page = 0
    peon = Peon.new(storehouse)
    file = 'last_page'

    if "#{file}.gz".in? peon.give_list() and update == 0
      page,limit, = peon.give(file:file).split(':').map { |i| i.to_i }
    end
    cobble = Dasher.new(:using=>:cobble, :redirect=>true) #, ssl_verify:false , :redirect=>true
    trying = 0

    loop do
        p page
        offset = page*limit+1
        url_main = "https://member.alaskabar.org/cvweb/cgi-bin/utilities.dll/CustomList?LASTNAME_field=&SORT=LASTNAME%2C+FIRSTNAME&LASTNAME=~&RANGE=#{offset}/#{limit}&SQLNAME=AKMEMDIR&WHP=Customer_Header.htm&WBP=Customer_List.htm&WNR=Customer_norec.htm"

        page_list_lawyers = cobble.get(url_main)

        general_lawyers_array = parse_list_lawyers(page_list_lawyers)

        if general_lawyers_array.empty?
          if trying>3
            mess = "\nEmpty: page#{page}|#{url_main}"
            log mess, :red
            Hamster.report(to:'Maxim Gushchin', message: mess, use: :slack)
            exit 0
          end
          #sleep(45**trying)
          trying+=1
          redo
        end


        bar_number_array = general_lawyers_array.map { |row| row[:bar_number] }

        existing_md5_hash = get_md5_hash(bar_number_array)
        full_lawyer_array = []
        md5_hash_array = []

        trying_lawyer=0

        general_lawyers_array.each do |lawyer|

          customercd = lawyer[:link].split('CUSTOMERCD=')[-1]
          begin

            # START GET ADDITIONAL INFO
            page_lawyer = cobble.get(lawyer[:link])
            lawyer_additional_data = parse_lawyer(page_lawyer)

            lawyer = lawyer.merge(lawyer_additional_data)

            # END GET ADDITIONAL INFO

            # START GET ADDRESS
            url_address_lawyer = "https://member.alaskabar.org/cvweb/cgi-bin/utilities.dll/customlist?SQLNAME=GETMEMDIRADDR&CUSTOMERCD=#{customercd}&ADDRESSTYPE=Work&wmt=none&whp=none&wbp=Customer_Address.htm&wnr=Customer_Address_None.htm"
            page_address_lawyer = cobble.get(url_address_lawyer)
            lawyer_address = parse_address_lawyer(page_address_lawyer)

            lawyer = lawyer.merge(lawyer_address)

            lawyer[:md5_hash] = make_md5(lawyer)

            if lawyer[:md5_hash].in? existing_md5_hash
              md5_hash_array.push(lawyer[:md5_hash])
              next
            end

          rescue => error
            if trying_lawyer>2
              mess = "\nError: #{lawyer[:link]}|#{error}"
              log mess, :red
              Hamster.report(to:'Maxim Gushchin', message: mess, use: :slack)
              exit 0
            end
            trying_lawyer+=1
            retry
          end


          lawyer = lawyer.merge(lawyer_additional_data)

          lawyer[:run_id] = @run_id
          lawyer[:touched_run_id] = @run_id
          #p lawyer
          full_lawyer_array.push(lawyer)

          trying_lawyer = 0

        end
        
        insert_all full_lawyer_array unless full_lawyer_array.empty?
        put_new_touched_id(md5_hash_array, @run_id)
        mark_deleted(existing_md5_hash-md5_hash_array)

        break if general_lawyers_array.length < limit

        peon.put(content: "#{page}:#{limit}:", file: file)
        page += 1
        trying = 0
    end
    peon.put(content: "1:#{limit}:", file: file)
    1
  end
end