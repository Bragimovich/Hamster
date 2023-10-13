# frozen_string_literal: true

require_relative '../lib/parser'
require_relative '../lib/scraper'
require_relative '../lib/keeper'


MAX_REC_NUM = 10_000
PER_PAGE = 1000
# WWW = '/searchterm/20151232-99999999/field/date/mode/exact/conn/and/order/date/ad/asc/page/48/maxRecords/200'
# ORDER = %w(title date dated relispt subjec subjec1 cita type descri)
# PAGE = '1'
# COLLECTION = %w(p17027coll8 p17027coll7 p17027coll5 p17027coll3)
TEST_URL = 'https://cdm17027.contentdm.oclc.org/digital/api/search/collection/p17027coll8/searchterm/2018/field/date/mode/exact/conn/and/order/date/ad/asc/page/1/maxRecords/3000'
# TEST_URL = 'https://cdm17027.contentdm.oclc.org/digital/api/search/collection/p17027coll7/searchterm/2019-2020/field/date/mode/exact/conn/and/order/date/ad/asc/page/1/maxRecords/1000'
# TEST_URL = 'https://cdm17027.contentdm.oclc.org/digital/api/search/collection/p17027coll8!p17027coll7!p17027coll5!p17027coll3/searchterm/2021-2021/field/date/mode/exact/conn/and/order/date/ad/asc/page/1/maxRecords/2000'
API_URL = 'https://cdm17027.contentdm.oclc.org/digital/api'
COLLECTION = '/search/collection/p17027coll8!p17027coll7!p17027coll5!p17027coll3'
SEARCHTERM = '/searchterm/20151232-99999999/field/date/mode/exact/conn/and/'
PARAMS = "/order/date/ad/desc/page/1/maxRecords/#{PER_PAGE}"

class Manager < Hamster::Scraper
  def initialize
    @scraper = Scraper.new
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def api
    items = []
    url = TEST_URL
    res = JSON.parse(@scraper.get_source(url))
    @keeper.store_items(res["items"])
  end

  def download
    @keeper.api_links.each {|link| @scraper.store("#{API_URL}#{link}")}
  end

  def parse
    pdf_list = @scraper.pdf_list
    # @scraper.pdf_list.sort[174.pred,1].each  do |pdf|
    # @scraper.pdf_list.sort[..-3].each  do |pdf|
    #   puts '*'*77, pdf
    #   res = @parser.parse_pdf(pdf)
    #   pp res, "size = #{res.size}" #if res[-1][0,4].eql?('xXxX')
    # end


    loop do
      obj = @scraper.next_file
      break unless obj.is_a?(Hash)

      puts '*'*77, "\n#{obj[:file_name]}"
      begin
        # @scraper.adjourn(obj[:file_name])
        api_res = @parser.parse_api(obj[:content])
# ========== UNCOMMENT THIS LINE ==========
        # @scraper.store_pdf(res[:activities][:file])
# ========== UNCOMMENT THIS LINE ==========

        link = api_res[:activities][:file]
        file_name = link.split('p17027').last.sub('/id/', '_').sub('/download', '.pdf')
        file_path = "#{@scraper.storehouse}store/#{file_name}"

        parties = @parser.parse_pdf(file_path).flatten.map {|el| el.merge(api_res[:additional_info])}
        api_res[:parties] = parties

        @keeper.store(api_res)
        @scraper.drop(obj[:file_name])
      rescue StandardError => e
        puts e, e.backtrace
        exit
        puts "Unable to parse! Removed to unprocessed..."
        @scraper.adjourn(obj[:file_name])
      end
    end
  end
end
# def add_dsu(a_of_h, d_s_u)
#   a_of_h.map {|el| el.merge({:data_source_url=> d_s_u})}
# end


# ==========================================================
# def api
#   items = []
#   # 1.upto(MAX_REC_NUM.div(PER_PAGE)) do |page|
#   #   url = "#{URL}#{COLLECTION}#{SEARCHTERM}#{PARAMS.sub("/1/", "/#{page}/")}"
#   url = TEST_URL
#     res = JSON.parse(@scraper.get_source(url))
#     # break if res["items"].empty?
#     @keeper.store_items(add_dsu(res["items"], url))
#     # items += res["items"]
#   # end
#     # puts '*'*77
#     # pp items.size
#     # pp items.uniq.size
#     # pp items.first
# end
