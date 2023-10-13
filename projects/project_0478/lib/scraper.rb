# frozen_string_literal: true

class Scraper < Hamster::Scraper
  attr_writer :link
  def link_by(number)
    @link = "https://guambar.org/system/homes/directory_listing/limit:100/page:#{number}?first_name=&last_name=&membership_class=&practice_area_id=&employer_type=&employer_name=&pay_for=Attorney&show_records=all"
  end

  def page_checked?
    @result = connect_to(@link)
    @result.status == 200
  end

  def html
   @result.body
  end

  def web_page
    web = "https://guambar.org#{@link}"
    res = connect_to(web)
    return nil if res.status == 302
    res.body
  end

  def lawyer_id
    @link.split('/').last
  end

  def clear
    trash_folder = "guambar_org"
    peon.list.each do |file|
        peon.move(file: file, to: trash_folder)
    end
  end
end
