# frozen_string_literal: true

class Scraper < Hamster::Scraper
  attr_writer :link
  
  def link_by(number)
    @link = "https://www.congress.gov/search?q=%7B%22source%22%3A%22nominations%22%2C%22congress%22%3A%22117%22%7D&pageSize=250&page=#{number}"
  end

  def page_checked?
    @result = connect_to(@link)
    @result.status == 200
  end

  def html
   @result.body
  end

  def congress_pn
    if @link.split('/').size == 4
      @pn = @link.split('/').last.split('?').first
    elsif @link.split('/').size == 5
      f_id = @link.split('/').last(2).first
      s_id = @link.split('/').last(2).last.split('?').first
      @pn = (f_id + "_" + s_id)
    end
  end

  def congress_id
    @id = @link.split('/').last.split('=').last
  end

  def web_page
    web = "https://www.congress.gov/nomination/117th-congress/#{@pn.gsub("_","/")}/all-info?r=#{@id}"
    loop do 
      res = connect_to(web)
      if res.body.size > 10000
        return res
        break
      else
        return res
      end
    end
  end

  def clear
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "Congress_gov_#{time}"
    peon.list.each do |file|
        peon.move(file: file, to: trash_folder)
    end
  end
end
