require_relative '../models/prlog_articles'
require_relative '../models/prlog_categories'
require_relative '../models/prlog_tags'
require_relative '../models/prlog_tags_article_links'
require_relative '../models/prlog_categories_article_links'
require_relative '../models/prlog_files'


COLUMNS = {
  :prlog_articles => %i[prlog_id title teaser article arcticle_link creator city state country date contact_info],
}


def put_articles_to_db(articles, scrape_date)
  existing_ids = get_articles_id(scrape_date)
  all_tags_hash = get_tag_id
  all_categories_hash = get_category_id

  prlog_articles_array = []
  prlog_tags_array = []
  prlog_categories_array = []
  prlog_files_array = []

  articles.each do |article|
    next if existing_ids.include?(article[:prlog_id])

    prlog_articles_array.push({})
    COLUMNS[:prlog_articles].each do |column|
      prlog_articles_array[-1][column.to_s] = article[column]
    end

    article[:tags].each do |tag|
      if !tag.downcase.in?(all_tags_hash.keys)
        all_tags_hash[tag.downcase] = add_new_tag(tag)
      end
      prlog_tags_array.push({'prlog_id': article[:prlog_id], 'prlog_tag_id': all_tags_hash[tag.downcase]})
    end

    article[:industries].each do |category|
      prlog_categories_array.push({'prlog_id': article[:prlog_id], 'prlog_category_id': all_categories_hash[category]})
    end

    article[:files].each do |file|
      prlog_files_array.push({'prlog_id': article[:prlog_id], 'title': article[:title], link: file})
    end

  end

  begin
    PrlogTagsArticleLinks.insert_all(prlog_tags_array) if !prlog_tags_array.empty?
  rescue
    put_additional_by_one(PrlogTagsArticleLinks, prlog_tags_array)
  end
  begin
    PrlogCategoriesArticleLinks.insert_all(prlog_categories_array) if !prlog_categories_array.empty?
  rescue
    put_additional_by_one(PrlogCategoriesArticleLinks, prlog_categories_array)
  end

  begin
    PrlogFiles.insert_all(prlog_files_array) if !prlog_files_array.empty?
  rescue
    put_additional_by_one(PrlogFiles, prlog_files_array)
  end

  begin
    PrlogArticles.insert_all(prlog_articles_array) if !prlog_articles_array.empty?
  rescue
    prlog_articles_array.each do |article|
      begin
        prlog_articles = PrlogArticles.new do |i|
          i.prlog_id = article['prlog_id']
          i.title =    article['title']
          i.teaser =   article['teaser']
          i.article =  article['article']
          i.arcticle_link = article['arcticle_link']
          i.creator = article['creator']
          i.city =    article['city']
          i.state =   article['state']
          i.country = article['country']
          i.date =    article['date']
          i.contact_info = article['contact_info']
        end
        prlog_articles.save
      rescue => e
        puts e
        path_to_file =  "logs/proj74_db_articles"
        File.open(path_to_file, 'a') { |file| file.write("#{article['prlog_id']}||#{article['arcticle_link']}: #{e}\n") }
      end
    end
  end

end

def get_category_id
  categories = {}
  PrlogCategories.all.map { |x| categories[x.category]=x.id}
  categories
end

def put_additional_by_one(db_model, prlog_additional_array)
  prlog_additional_array.each do |additional|
    begin
      db_model.create(additional)
    rescue
      next
    end
  end
end

def get_tag_id
  tags = {}
  PrlogTags.all.map { |x| tags[x.tag.downcase]=x.id}
  tags
  #PrlogTags.where(tag:tag).first.id
end

def add_new_tag(tag)
  PrlogTags.create(tag:tag)
  PrlogTags.find_by(tag:tag).id
end


ALL_TAG = get_tag_id
ALL_CATEGORIES = get_category_id

def put_article_additional(article)
  prlog_tags_array = []
  prlog_categories_array = []
  prlog_files_array = []

  article[:tags].each do |tag|
    p ALL_TAG[tag]
    prlog_tags_array.push({'prlog_id': article[:prlog_id], 'prlog_tag_id': ALL_TAG[tag]})
  end

  article[:industries].each do |category|
    prlog_categories_array.push({'prlog_id': article[:prlog_id], 'prlog_category_id': ALL_CATEGORIES[category]})
  end

  article[:files].each do |file|
    prlog_files_array.push({'prlog_id': article[:prlog_id], 'title': article[:title], link: file})
  end


  PrlogTagsArticleLinks.insert_all(prlog_tags_array) if !prlog_tags_array.empty?
  PrlogCategoriesArticleLinks.insert_all(prlog_categories_array) if !prlog_categories_array.empty?
  PrlogFiles.insert_all(prlog_files_array) if !prlog_files_array.empty?
end


def get_articles_id(scrape_date)
  prlog_ids = Array.new()
  PrlogArticles.where(date:scrape_date).each { |q| prlog_ids.push(q.id) }
  prlog_ids
end



def put_categories(categories)
  PrlogCategories.insert_all(categories)
end

def put_tags(tags)
  PrlogTags.insert_all(tags)
end


def put_old_articles(article)
  prlog_articles = PrlogArticles.new do |i|
    i.prlog_id = article[:prlog_id]
    i.title =    article[:title]
    i.teaser =   article[:teaser]
    i.article =  article[:article]
    i.arcticle_link = article[:arcticle_link]
    i.creator = article[:creator]
    i.city =    article[:city]
    i.state =   article[:state]
    i.country = article[:country]
    i.date =    article[:date]
    i.contact_info = article[:contact_info]
  end
  prlog_articles.save
end


def connect_to_db #us_court_cases
  Mysql2::Client.new(Storage[host: :db02, db: :press_releases].except(:adapter).merge(symbolize_keys: true))
end


def tags_not_exists(year=2021, month=9) #TODO: fill empty tags and categories
  client = connect_to_db
  query = "SELECT prlog_id, date, arcticle_link FROM prlog_articles WHERE YEAR(date)=#{year} AND MONTH(date)=#{month} AND prlog_id not in
               (SELECT prlog_id from prlog_tags_article_links WHERE prlog_id in
                (SELECT prlog_id FROM prlog_articles_backup WHERE YEAR(date)=#{year} AND MONTH(date)=#{month}))
                AND prlog_id not in (SELECT prlog_id from prlog_tags_article_links WHERE prlog_id in
                (SELECT prlog_id FROM prlog_articles_backup WHERE YEAR(date)=#{year} AND MONTH(date)=#{month}))"
            #LIMIT #{limit} OFFSET #{offset}"
  client.query(query)
end