# frozen_string_literal: true

def parse_list_gifts(html)
  #doc = Nokogiri::HTML(html)
  gifts = []

  gifts_in_file = html.split('module.productsStore.set(')[-1].split('</script>')[0].split(');')[0..-2].join(');')

  gifts_json = JSON.parse(gifts_in_file)


  gifts_json['data'].each do |gift|
    gifts.push({
                 id: gift['id'],
                 producer_name: gift['brand_name'],
                 product_name: gift['product_name'],
                 product_short_description: gift['description'],
                 product_price_min: gift['min_price'],
                 product_price_max: gift['max_price'],
                 rating: gift['review_rating'].to_i/20,
                 product_img_url: gift['image'],
                 product_url: gift['url'],

                 product_highlights: gift['product_highlights'],
                 product_type_id: gift['type_id'],
                 grommet_category: gift['grommet_category'],
                 json_general: gift.to_s,
      })
  end
  gifts
end


def parse_gift(html)
  #doc = Nokogiri::HTML(html)

  gifts_in_file = html.split("module.product.set(")[-1].split('</script>')[0].split(');')[0..-2].join(');')
  gift_json = JSON.parse(gifts_in_file)

  gift = {
    product_brand_name: gift_json['brand_name'],
    product_description: gift_json['description'],

    json_big: gift_json.to_s,
  }
  gift
end




def parse_gift_out_of_stock(html)
  try_offers = html.split('"offers": [')[1]

  if !try_offers.nil?
    offers = try_offers.split(']')[0]
  else
    try_offers2 = html.split('"offers": {')[1]
    return FALSE if try_offers2.nil?
    offers= try_offers2.split('}')[0]
    offers = "{#{offers}}"
  end

  offers_json = JSON.parse("[#{offers}]")
  offers_json.each do |offer|
    return FALSE if offer["availability"].in?(["InStock", "Discontinued"])
  end
  return TRUE
end


def parse_review_count(html)
  try_rating = html.split('"aggregateRating": {')[1]
  return 0 if try_rating.nil?
  rating = try_rating.split('},')[0]
  aggregate_rating = JSON.parse("{#{rating}}")
  aggregate_rating["reviewCount"]
end

def parse_categories(html)
  doc = Nokogiri::HTML(html)
  categories = []

  doc.css('.full-bleed-phone').css('.txt-a-center').each do |category_html|

    category = category_html.css('.f-serif-19')[0].content.strip
    category_html.css('.p-b-s').each do |sub_category_html|
      categories.push({
                        category: category,
                        sub_category: sub_category_html.content.strip,
                        category_url: sub_category_html.css('a')[0]['href']
                      })
    end
  end
  categories
end


def parse_sub_categories(html)
  doc = Nokogiri::HTML(html)
  sub_categories = []
  doc.css('.scrollable-horz-tablet')[0].css('a').each do |sub_cat|
    sub_categories.push({
                          sub_category: sub_cat.content,
                          url: sub_cat['href']
                        })

  end
  sub_categories
end

def parse_all_categories(html)
  page_json = html.split('hydrate(module.MobileMenu, componentEnd,')[-1].split('</script>')[0].split(')')[0][14..]

  page_hash = JSON.parse(page_json)

  categories = []
  page_hash['items'].each do |fields|
    #p fields
    category_name = fields['name']
    next if fields["children"].nil?
    fields["children"].each do |sub_cat|
      categories.push({
                        category: category_name,
                        sub_category: sub_cat['name'],
                        category_url: 'https://www.thegrommet.com' + sub_cat['url'],

                      })

      next if sub_cat["children"].nil?
      sub_cat["children"].each do |sub_sub_cat|
        categories.push({
                          category: category_name,
                          sub_category: sub_sub_cat['name'],
                          category_url: 'https://www.thegrommet.com' + sub_sub_cat['url'],

                        })
      end

    end
  end
  categories
end