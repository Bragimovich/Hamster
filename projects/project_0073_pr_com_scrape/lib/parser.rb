# frozen_string_literal: true

require_relative '../models/pr_com_files'
require_relative '../models/pr_com_articles'
require_relative '../models/pr_com_categories'
require_relative '../models/pr_com_categories_article_links'
require_relative '../models/pr_com_subcategories'
require_relative '../models/pr_com_subcategories_article_links'

class Parser < Hamster::Parser
  def parse_pr_list(page_body)
    doc = Nokogiri::HTML page_body
    result = []
    doc.css('section.grid-x.release-list__item').each do |section|
      pr_url = section.children.children.children[0].first.last

      if pr_url.include? 'img.pr.com'
        img_link = section.children.children.children[0].first.last
        pr_url = section.children.children.children[1].first.last
        title = section.children.children.children.children.text
        teaser_date_creator = section.children.children.children.last.text
      else
        title = section.children.children.children.children.text
        teaser_date_creator = section.children.children.children[1].text
      end

      divided_teaser_date_creator = teaser_date_creator.split(' - ')
      creator = divided_teaser_date_creator.last.strip

      date = nil
      begin
        date = Date.strptime(divided_teaser_date_creator[-2].strip, '%B %d, %Y')
      rescue StandardError => e
        logger.debug e
        logger.debug e.backtrace
      end

      divided_teaser_date_creator.delete_at(-1)
      divided_teaser_date_creator.delete_at(-1)

      teaser = divided_teaser_date_creator.join('-')
      article_data = {
          title: title,
          link: "https://www.pr.com#{pr_url}",
          date: date,
          creator: creator,
          teaser: teaser,
          pr_url: pr_url,
          img_link: img_link
      }
      result.push(article_data)
    end
    result
  end

  def parse_single_pr(article_data, pr_response)
    html_doc = Nokogiri::HTML pr_response.body

    city_state_date = html_doc.css('div.press-release__text').children.first.text
    city = city_state_date.split(',').first.strip
    state = city_state_date.split(',')[1].strip

    pr_article = ''
    html_doc.css('div.press-release__text').children.drop(2).each do |item|
      pr_article += item.to_s
    end
    article = pr_article.gsub('<br>', '\n').gsub(')--', '').gsub(160.chr("UTF-8"), '')
    contact_info = html_doc.css('div.press-release__contact-info').children.to_html
    data_source_url = "https://www.pr.com#{article_data[:pr_url]}"

    article_page_data = {
      city: city,
      state: state,
      article: article,
      contact_info: contact_info,
      data_source_url: data_source_url
    }
    article_data.merge(article_page_data)
  end

  def parse_categories_with_links(html)
    doc = Nokogiri::HTML html
    doc.css('li.is-parent.is-twitter.has-link')
  end

  def parse_category_with_url(item)
    relative_category_url = item.children.children[1]['href']
    category_name = item.children.children[1].children.text # name of each category

    category = {}
    category[:category] = category_name
    category[:data_source_url] = 'https://www.pr.com/news-by-category'
    {
      relative_category_url: relative_category_url,
      category: category
    }
  end

  def parse_category_articles(html, category_hash, page: nil)
    html_doc = Nokogiri::HTML html
    category_article_data = []
    html_doc.css('h2.release-list__title').each do |h2|
      category_article_link = {}
      category_article_link[:article_link]      = "https://www.pr.com#{h2.children[0]['href']}"
      category_article_link[:data_source_url]    = if page.nil?
                                                   "https://www.pr.com#{category_hash[:relative_category_url]}"
                                                 else
                                                   "https://www.pr.com#{category_hash[:relative_category_url]}/+#{page}"
                                                 end

      category_article_data << category_article_link
    end
    category_article_data
  end

  def parse_subcategories_and_links(html)
    doc = Nokogiri::HTML html
    doc.css('ul.list--grouped.no-bullet li h3')
  end

  def parse_subcategory_with_url(item)
    relative_subcategory_url = item.children[1]['href']
    subcategory_name = item.children.children.text # name of each subcategory

    subcategory = {}
    subcategory[:subcategory] = subcategory_name
    subcategory[:data_source_url] = 'https://www.pr.com/news-by-category'

    {
      relative_subcategory_url: relative_subcategory_url,
      subcategory: subcategory
    }
  end

  def parse_subcategory_articles(html, subcategory_hash, page: nil)
    html_doc = Nokogiri::HTML html
    sub_category_article_data = []
    html_doc.css('h2.release-list__title').each do |h2|
      sub_category_article_link = {}
      sub_category_article_link[:article_link] = "https://www.pr.com#{h2.children[0]['href']}" # url to single press_release from sub_category
      sub_category_article_link[:data_source_url] = if page.nil?
                                                    "https://www.pr.com#{subcategory_hash[:relative_subcategory_url]}"
                                                  else
                                                    "https://www.pr.com#{subcategory_hash[:relative_subcategory_url]}/+#{page}"
                                                  end
      sub_category_article_data << sub_category_article_link                                           
    end
    sub_category_article_data
  end

  private

  def store_category(category_name)
    category = {}
    category[:category] = category_name
    category[:data_source_url] = 'https://www.pr.com/news-by-category'
    category
  end
end
