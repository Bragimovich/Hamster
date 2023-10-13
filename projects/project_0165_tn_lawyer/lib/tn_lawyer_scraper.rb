# frozen_string_literal: true

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[bar_number name law_firm_city law_firm_zip law_firm_county law_firm_state registration_status law_school used_names]
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
    #scrape_answer = gathering(update)
    scrape_answer = gathering_new_abc(update)
    if scrape_answer == 1
      deleted_for_not_equal_run_id(@run_id)
      run_id_class.finish
    end
  end

  def gathering(update)
    limit = 25
    page = 1
    peon = Peon.new(storehouse)
    file = 'last_page'

    if "#{file}.gz".in? peon.give_list() and update == 0
      page, = peon.give(file:file).split(':').map { |i| i.to_i }
    end
    cobble = Dasher.new(:using=>:cobble, :redirect=>true) #, ssl_verify:false , :redirect=>true
    trying = 0

    loop do
        p page

        url_main = "https://www.tbpr.org/attorneys/search?attorney%5Bbpr_number%5D=&attorney%5Bcity%5D=&attorney%5Bcounty%5D=&attorney%5Bfirst_name%5D=&attorney%5Binclude_attorneys_without_addresses%5D=&attorney%5Blast_name%5D=&attorney%5Bstatus%5D%5Ball%5D=511&page=#{page}"


        page_list_lawyers = cobble.get(url_main)
        #peon.put content:page_list_lawyers, file: letter
        #redo if page_list_lawyers.nil?

        general_lawyers_array = parse_list_lawyers(page_list_lawyers)


        if general_lawyers_array.empty?
          if trying>3
            mess = "\nEmpty: page#{page}|#{url_main}"
            log mess, :red
            Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
            exit 0
          end
          sleep(45**trying)
          trying+=1
          redo
        end


        bar_number_array = general_lawyers_array.map { |row| row[:bar_number] }

        existing_md5_hash = get_md5_hash(bar_number_array)
        full_lawyer_array = []
        md5_hash_array = []

        trying_lawyer=0

        general_lawyers_array.each do |lawyer|
          next if lawyer['name']=='zxc, sfg'
          begin
            page_lawyer = cobble.get(lawyer[:link])
            lawyer_additional_data = parse_lawyer(page_lawyer)

          rescue => error
            if trying_lawyer>2
              mess = "\nError: #{lawyer[:link]} | #{error}"
              log mess, :red
              Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
              exit 0
            end
            trying_lawyer+=1
            retry
          end


          lawyer = lawyer.merge(lawyer_additional_data)

          lawyer[:md5_hash] = make_md5(lawyer)
          if lawyer[:md5_hash].in? existing_md5_hash
            md5_hash_array.push(lawyer[:md5_hash])
            next
          end

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

        peon.put(content: "#{page}:", file: file)
        page += 1
        trying = 0
    end

    peon.put(content: "1:", file: file)
    1
  end

  def gathering_new_abc(update)
    limit = 50

    peon = Peon.new(storehouse)
    file = 'last_page_abc'

    if "#{file}.gz".in? peon.give_list() and update == 0
      first_page, first_letter, = peon.give(file:file).split(':').map { |i| i }
    end
    cobble = Dasher.new(:using=>:cobble, :redirect=>true) #, ssl_verify:false , :redirect=>true
    trying = 0
    ('a'..'z').each do |letter|
      if first_page.nil?
        page = 1
      else
        page = first_page.to_i
        first_page = nil
      end

      if !first_letter.nil?
        if letter==first_letter
          first_letter=nil
        else
          next
        end
      end
      loop do
        p page
        url_main = "https://www.tbpr.org/attorneys?last_name_starts_with=#{letter}&page=#{page}"

        page_list_lawyers = cobble.get(url_main)
        #peon.put content:page_list_lawyers, file: letter
        #redo if page_list_lawyers.nil?

        general_lawyers_array = parse_list_lawyers_abc(page_list_lawyers)

        # if general_lawyers_array.empty?
        #   if trying>3
        #     mess = "\nEmpty: page#{page}|#{url_main}"
        #     log mess, :red
        #     Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
        #     exit 0
        #   end
        #   sleep(45**trying)
        #   trying+=1
        #   redo
        # end


        bar_number_array = general_lawyers_array.map { |row| row[:bar_number] }

        existing_md5_hash = get_md5_hash(bar_number_array)
        full_lawyer_array = []
        md5_hash_array = []

        trying_lawyer=0

        general_lawyers_array.each do |lawyer|
          begin
            page_lawyer = cobble.get(lawyer[:link])
            lawyer_additional_data = parse_lawyer(page_lawyer)

          rescue => error
            if trying_lawyer>2
              mess = "\nError: #{lawyer[:link]} | #{error}"
              log mess, :red
              Hamster.report(to:'Maxim Gushchin', message: mess, use: :both)
              exit 0
            end
            trying_lawyer+=1
            retry
          end


          lawyer = lawyer.merge(lawyer_additional_data)

          lawyer[:md5_hash] = make_md5(lawyer)
          if lawyer[:md5_hash].in? existing_md5_hash
            md5_hash_array.push(lawyer[:md5_hash])
            next
          end

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
        page += 1
        peon.put(content: "#{page}:#{letter}:", file: file)
        trying = 0
      end
    end

    peon.put(content: "1:a:", file: file)
    1
  end
end