# frozen_string_literal: true

class Match < Hamster::Scraper

  def initialize(**args)
    matching
  end

  def matching
    GrommetProductKeywords.where(done:0).each do |keyword|
      split_keyword = keyword.keyword.split(' ')
      count_words = split_keyword.length

      product_to_keywords = {}

      split_keyword.each do |part_key|
        p part_key
        prod_with_keyword = GrommetGiftsProducts.where("product_description like '%#{part_key}%'"\
                              "or product_short_description like '%#{part_key}%'"\
                              "or product_highlights like '%#{part_key}%'"\
                              "or grommet_category like '%#{part_key}%'"\
                              "or product_name like '%#{part_key}%'")

        prod_with_keyword.each do |prod|
          if prod.id.in?(product_to_keywords)
            product_to_keywords[prod.id]-=1
          else
            product_to_keywords[prod.id] = count_words - 1
          end
        end
      end
      product_to_keywords.each do |prod_id, value|
        if value == 0
          GrommetProductToKeyword.insert({
                                           product_id: prod_id,
                                           keyword_id: keyword.id,
                                         })
        end
      end
    end
  end


end