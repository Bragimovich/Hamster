require_relative '../models/pr_com_articles.rb'
require_relative '../models/pr_com_categories_article_links'
require_relative '../models/pr_com_categories'
require_relative '../models/pr_com_files'
require_relative '../models/pr_com_subcategories_article_links.rb'
require_relative '../models/pr_com_subcategories'

class Keeper
  def store_pr_data(data)
    data.each do |data_hash|
        pr_com_article = PrComArticles.find_by(title: data_hash['title'], creator: data_hash['creator'])
        if pr_com_article.present?
          if pr_com_article.link != pr_com_article.data_source_url
            pr_com_article.update(link: data_hash['link'])
          end
          pr_com_article
        else
          begin
            pr_com_article = PrComArticles.create(
              title: data_hash['title'],
              date: data_hash['date'],
              creator: data_hash['creator'],
              link: data_hash['link'],
              teaser: data_hash['teaser'],
              city: data_hash['city'],
              state: data_hash['state'],
              article: data_hash['article'],
              contact_info: data_hash['contact_info'],
              data_source_url: data_hash['data_source_url']
            )
          rescue StandardError => e
            next
          end
        end
        
      pr_com_files = PrComFiles.find_by(title: data_hash['title'])
      if pr_com_files.present?
        next if pr_com_files.link != pr_com_files.data_source_url
        begin
          pr_com_files.update(link: data_hash['img_link'])
        rescue StandardError => e
          logger.info e
          logger.info e.backtrace
        end
      else
        pr_com_file = PrComFiles.new(
          title: data_hash['title'],
          link: data_hash['img_link'],
          data_source_url: data_hash['data_source_url'],
        )
        pr_com_file.pr_come_id = pr_com_article.id
        begin
          pr_com_file.save
        rescue StandardError => e
          logger.info e
          logger.info e.backtrace
        end
      end
    end
  end

  def store_catagory_data(data)
    category = PrComCategories.find_or_create_by(category: data['category']['category'], data_source_url: data['category']['data_source_url'])
    
    data['category_article'].each do |category_article|
      next if PrComCategoriesArticleLinks.where(article_link: category_article['article_link']).present?
 
      category_article_link = PrComCategoriesArticleLinks.new(category_article)
      category_article_link.pr_com_category_id = category.id
      begin
        category_article_link.save
      rescue StandardError => e
        logger.info e
        logger.info e.backtrace
      end
    end
  end

  def store_sub_catagory_data(data)
    subcategory = PrComSubcategories.find_or_create_by(subcategory: data['subcategory']['subcategory'], data_source_url: data['subcategory']['data_source_url'])

    data['subcategory_article'].each do |subcategory_article|
      next if PrComSubcategoriesArticleLinks.where(article_link: subcategory_article['article_link']).present?
      subcategory_article_link = PrComSubcategoriesArticleLinks.new(subcategory_article)
      subcategory_article_link.pr_com_subcategory_id = subcategory.id

      begin
        subcategory_article_link.save
      rescue StandardError => e
        logger.info e
        logger.info e.backtrace
      end
    end
  end
end
