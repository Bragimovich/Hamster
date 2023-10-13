# frozen_string_literal: true

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[bar_number name law_firm_name law_firm_state date_admitted]
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
    if scrape_answer ==1
      deleted_for_not_equal_run_id(@run_id)
      run_id_class.finish
    end
  end

  def gathering(update)
    limit = 100
    page = 1
    peon = Peon.new(storehouse)
    file = 'last_page'

    if "#{file}.gz".in? peon.give_list() and update == 0
      page, limit, = peon.give(file:file).split(':').map { |i| i.to_i }
    end
    cobble = Dasher.new(:using=>:cobble) #, ssl_verify:false


    loop do
        p page

        url_main = "https://www.ohiobar.org/FindALawyerSearch?sortData={%22criteria%22:%22nameAZ%22,%22pageNumber%22:#{page},%22pageLength%22:#{limit},%22Positions%22:[4122,15739,3423,13904,3072,193,18964,3570,210,10057,4903,17260,4206,4364,2878,2625,16525,19411,9887,18147,3032,10972,4232,13676,11749,13162,16868,395,13095,12761,2036,6459,17119,5893,12446,13034,868,10492,17912,12604,10211,2034,6255,8193,2735,9184,18135,9731,8125,16998,360,18148,4683,13540,18225,6375,10081,8848,4674,9622,18273,8950,1708,9939,4492,10690,13881,4117,12172,3730,16867,10227,3332,12006,15300,11576,7566,5680,16870,8888,10704,15302,16481,2333,13975,1962,4477,12579,5057,9758,9861,6681,8720,15361,8244,16770,7011,2204,11451,2792],%22SortField%22:%22Name%22,%22SortDescending%22:false}&searchData=[{%22Name%22:%22AreasOfLaw%22,%22Values%22:[]},{%22Name%22:%22Certifications%22,%22Values%22:[]},{%22Name%22:%22Languages%22,%22Values%22:[]},{%22Name%22:%22Location%22,%22Values%22:[]},{%22Name%22:%22PracticeAreas%22,%22Values%22:[]}]"
        page_list_lawyers = cobble.get(url_main)

        #peon.put content:page_list_lawyers, file: letter

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

          lawyer[:run_id] = @run_id
          lawyer[:touched_run_id] = @run_id

          full_lawyer_array.push(lawyer)

        end
        insert_all full_lawyer_array unless full_lawyer_array.empty?
        put_new_touched_id(md5_hash_array, @run_id)

        break if general_lawyers_array.length < limit

        peon.put(content: "#{page}:#{limit}:", file: file)
        page += 1
    end
    peon.put(content: "1:#{limit}:", file: file)
    1
  end
end