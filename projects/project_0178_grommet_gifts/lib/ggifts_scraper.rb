# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize(**args)
    super
    # run_id_class = RunId.new()
    # @run_id = run_id_class.run_id
    get_more_categories if args[:categories]
    gathering if args[:download]
    # store() if args[:store]
    # update() if args[:update]

    # deleted_for_not_equal_run_id(@run_id)
    # run_id_class.finish
  end


  def gathering
    cobble = Dasher.new(:using=>:cobble, :redirect=>true) #, ssl_verify:false , :redirect=>true


    categories = categories_from_db
    categories.each_pair do |category_id, url|
      p "Category_id: #{category_id}"
      page = 1
      loop do
        p page
        url_list_gifts = url + "?page=#{page}"

        html_list_gifts = cobble.get(url_list_gifts)

        list_gifts = parse_list_gifts(html_list_gifts)

        gift_urls = list_gifts.map {|g| g[:id]}
        existing_gift_ids = get_existing_gifts(gift_urls)

        save_gift = []
        gift_category = []
        list_gifts.each do |gift|
          if gift[:id].to_i.in? existing_gift_ids
            add_new_category_to_product(gift[:id], category_id)
            next
          end
          next if gift[:product_url].nil?
          gift_page = cobble.get(gift[:product_url])
          redo if gift_page.nil?
          gift[:is_sold_out] = parse_gift_out_of_stock(gift_page)
          gift[:reviews_count] = parse_review_count(gift_page)
          gift = gift.merge(parse_gift(gift_page))
          save_gift.push(gift)
          gift_category.push({product_category_id:category_id, product_id: gift[:id] })
        end

        GrommetGiftsProducts.insert_all(save_gift) if !save_gift.empty?
        GrommetGiftsProductCategories.insert_all(gift_category) if !gift_category.empty?

        break if list_gifts.length<64
        page+=1
      end




    end


  end





  def get_categories
    url = 'https://www.thegrommet.com/gifts'
    cobble = Dasher.new(:using=> :cobble)
    html = cobble.get(url)
    categories = parse_categories(html)
    GrommetGiftsCategories.insert_all(categories)

  end

  def get_more_categories_old
    main_url = 'https://www.thegrommet.com'
    categories = {}
    GrommetGiftsCategories.all().group(:category).each { |cat| categories[cat.category]=cat.category_url }

    all_category_url = GrommetGiftsCategories.all().map { |q| q.category_url }
    cobble = Dasher.new(:using=>:cobble, :redirect=>true)
    categories.each_pair do |category, url|

      page = cobble.get(url)

      sub_categories = parse_sub_categories(page)

      new_sub_categories = []

      sub_categories.each do |sub_cat|
        sub_cat[:url] = main_url + sub_cat[:url]
        next if sub_cat[:url].in?(all_category_url)
        new_sub_categories.push({
                                  category: category,
                                  sub_category: sub_cat[:sub_category],
                                  category_url: sub_cat[:url]
                                })
      end

      GrommetGiftsCategories.insert_all(new_sub_categories) if !new_sub_categories.empty?
    end

  end

  def get_more_categories
    main_url = 'https://www.thegrommet.com'


    cobble = Dasher.new(:using=>:cobble, :redirect=>true)

    page = cobble.get(main_url)
    categories = parse_all_categories(page)

    new_sub_categories = []

    # categories.each do |sub_cat|
    #     sub_cat[:url] = main_url + sub_cat[:url]
    #     next if sub_cat[:url].in?(all_category_url)
    #     new_sub_categories.push({
    #                               category: category,
    #                               sub_category: sub_cat[:sub_category],
    #                               category_url: sub_cat[:url]
    #                             })
    #   end

    GrommetGiftsCategories.insert_all(categories) if !categories.empty?


  end

end