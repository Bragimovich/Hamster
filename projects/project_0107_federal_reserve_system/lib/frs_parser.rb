# frozen_string_literal: true
#
require 'yaml'
require_relative '../models/us_dept_frs'

class FRSParser < Hamster::Parser
  SUB_PATH = '/newsevents/pressreleases.htm'
  SUB_FOLDER = 'federal_reserve_system/'

  def start
    begin
      store
    rescue => e
      [STARS,  e].each {|line| logger.fatal(line)}
      Hamster.report(to: OLEKSII_KUTS, message: "Project # 0107 --store: Error - \n#{e}", use: :slack)
    end
  end

  def store
    mark_as_started
    process_current_pages
    mark_as_finished
    # files_to_trash
  end

  def process_current_pages
    last_run = UsDeptFrsRuns.last
    @run_id = last_run.id
    process_each_file
  end

  def process_each_file
    begin
      files = peon.give_list(subfolder: SUB_FOLDER)

      loop do
        break if files.empty?
        file = files.pop
        file_content = peon.give(subfolder: SUB_FOLDER, file: file)
        result = parse(file_content, file)
        next if result.nil?
      end
    rescue => e
      [STARS,  e].each {|line| logger.error(line)}
      Hamster.report(to: OLEKSII_KUTS, message: "Project # 0107 --store: Error - \n#{e}", use: :slack)
    end
  end

  def is_blank?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_children_are_blank?(node)
    node.children.all? {|child| is_blank?(child)}
    # Here you see the convenience of monkeypatching... sometimes.
  end

  def parse(file_content, file)
    begin

    file_name = file.gsub('.gz', '')
    logger.info(file_name)

    article_doc = Nokogiri::HTML(file_content).at('#article').css('.col-xs-12.col-sm-8.col-md-8')
    article_doc.search('.heading').children.remove
    article_doc.search('.heading').remove
    article_doc.search('.panel.panel-attachments').children.remove
    article_doc.search('.panel.panel-attachments').remove
    article_doc.search('.mediaContacts').children.remove
    article_doc.search('.mediaContacts').remove
    article_doc.search('.col-xs-12.col-md-7.pull-right.margin-t2b2').remove

    article_doc.css('div').find_all {|div| all_children_are_blank?(div)}.each do |div|
      div.remove
    end

    article = article_doc.children.to_html.strip

    teaser_doc = Nokogiri::HTML(file_content).at('#article').css('.col-xs-12.col-sm-8.col-md-8')
    teaser_doc.search('.heading').children.remove
    teaser_doc.search('.heading').remove
    teaser_doc.search('.panel.panel-attachments').children.remove
    teaser_doc.search('.panel.panel-attachments').remove
    teaser_doc.search('.mediaContacts').children.remove
    teaser_doc.search('.mediaContacts').remove
    teaser_doc.search('.col-xs-12.col-md-7.pull-right.margin-t2b2').remove

    bureau_office_doc = Nokogiri::HTML(file_content).at('#article').css('.list-unstyled.press-info')
    bureau_office = bureau_office_doc.size == 0 ? nil : bureau_office_doc.children.map {|a| a.text}.reject(&:blank?).to_json

    contact_info_doc = Nokogiri::HTML(file_content).at('#article').css('.col-xs-12.col-sm-8.col-md-8').css('.mediaContacts').css('.contacts')
    contact_info = contact_info_doc.size == 0 ? nil : contact_info_doc.children.to_html

    begin
      if teaser_doc.search('p').first.present?
        teaser = teaser_doc.search('p').first.text.strip
        if teaser.gsub(/[[:space:]]/, '') == '' && teaser_doc.search('p')[1].present?
          teaser = teaser_doc.search('p')[1].text.strip
          if teaser.gsub(/[[:space:]]/, '') == '' && teaser_doc.search('p')[2].present?
            teaser = teaser_doc.search('p')[2].text.strip
          end
        end
      else
        teaser = article.strip
      end
      teaser = TeaserCorrector.new(teaser).correct

    rescue => e
      [STARS, file_name, 'first', e].each {|line| logger.error(line)}
      Hamster.report(to: OLEKSII_KUTS, message: "Project # 0107 --store: Error - \n#{e}", use: :slack)
    end

    yaml_storage_path = "#{ENV['HOME']}/HarvestStorehouse/project_0107/store/yaml/rows.yml"
    additional_info = YAML.load(File.read(yaml_storage_path)).reduce Hash.new, :merge
    return nil if additional_info[file_name].nil?

    us_dept_frs = UsDeptFrs.new
    us_dept_frs_categories_article_links = UsDeptFrsCategoriesArticleLinks.new

    us_dept_frs.run_id = @run_id
    us_dept_frs.title = additional_info[file_name][1]
    us_dept_frs.teaser = teaser
    us_dept_frs.article = article.strip
    us_dept_frs.link = additional_info[file_name][0]
    us_dept_frs.creator = 'Board of Governors of the Federal Reserve System'
    us_dept_frs.type = us_dept_frs.link.split('/')[-2].sub('releases', ' release')
    us_dept_frs.country = 'US'
    date = DateTime.strptime(additional_info[file_name][3], "%m/%d/%Y")
    us_dept_frs.date = date
    us_dept_frs.bureau_office = bureau_office
    us_dept_frs.contact_info = contact_info
    us_dept_frs.scrape_frequency = 'daily'
    us_dept_frs.data_source_url = 'https://www.federalreserve.gov/newsevents.htm'

    us_dept_frs.save if UsDeptFrs.find_by(link: us_dept_frs.link).nil?

    category = additional_info[file_name][2]
    us_dept_frs_categories_article_links.article_link = us_dept_frs.link
    UsDeptFrsCategories.new(category: category).save if UsDeptFrsCategories.find_by(category: category).nil?
    us_dept_frs_categories_article_links.prlog_category_id = UsDeptFrsCategories.find_by(category: category).id
    us_dept_frs_categories_article_links.save if UsDeptFrsCategoriesArticleLinks.find_by(article_link: us_dept_frs.link).nil?
    rescue => e
      [STARS, file, 'last', e].each {|line| logger.error(line)}
      Hamster.report(to: OLEKSII_KUTS, message: "Project # 0107 --store: Error - \n#{e} \n#{file}", use: :slack)
    end
  end

  def mark_as_started
    last_run = UsDeptFrsRuns.last
    UsDeptFrsRuns.find(last_run.id).update(status: 'store started')
  end

  def mark_as_finished
    last_run = UsDeptFrsRuns.last
    UsDeptFrsRuns.find(last_run.id).update(status: 'store finished')
  end

  def files_to_trash
    trash_folder = SUB_FOLDER
    peon.list.each do |zip|
      peon.give_list(subfolder: zip).each do |file|
        peon.move(file: file, from: zip, to: trash_folder)
      end
    end
  end
end
