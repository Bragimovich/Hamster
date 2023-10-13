# frozen_string_literal: true

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[bar_number name law_firm_name law_firm_state date_admitted registration_status]
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
    gathering(update)

    deleted_for_not_equal_run_id(@run_id)
    run_id_class.finish
  end

  def gathering(update)
    limit = 10
    first_letter = 'A'
    peon = Peon.new(storehouse)
    file = 'last_page'

    if "#{file}.gz".in? peon.give_list() and update == 0
      first_letter, = peon.give(file:file).split(':')
    end
    cobble = Dasher.new(:using=>:cobble) #, ssl_verify:false


    (first_letter..'Z').each do |letter|
        p letter
        url_main = "https://nvbar.org/for-the-public/find-a-lawyer/?usearch=#{letter}"

        page_list_lawyers = cobble.get(url_main)
        peon.put content:page_list_lawyers, file: letter

        general_lawyers_array = parse_list_lawyers(page_list_lawyers)


        bar_number_array = general_lawyers_array.map { |row| row[:bar_number] }

        existing_md5_hash = get_md5_hash(bar_number_array)
        full_lawyer_array = []
        md5_hash_array = []

        general_lawyers_array.each do |lawyer|
          lawyer[:md5_hash] = make_md5(lawyer)
          if lawyer[:md5_hash].in? existing_md5_hash
            md5_hash_array.push(lawyer[:md5_hash])
            next
          end
          lawyer[:link] = url_main

          lawyer[:run_id] = @run_id
          lawyer[:touched_run_id] = @run_id

          full_lawyer_array.push(lawyer)

        end
        insert_all full_lawyer_array unless full_lawyer_array.empty?

        put_new_touched_id(md5_hash_array, @run_id)

        peon.put(content: "#{letter}:", file: file)
    end
  end
end