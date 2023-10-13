require_relative '../lib/converter'

class Parser < Hamster::Parser
  attr_reader :html

  def initialize(run_id = 0)
    super
    @dirty_news = []
    @run_id = run_id
    @converter = Converter.new(@run_id)
  end

  def html=(html)
    return if html.blank?

    @html = Nokogiri::HTML(html.to_s.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8))
    @lang_tag = @html.css('html').attribute('lang').to_s
    @html
  end

  def browser=(browser)
    @is_browser = true
    @browser = browser
    @html = browser #TODO ADD .to_s.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8)
  end

  def set_params(**params)
    @css = params[:css] || nil
    @type = params[:type] || 'text'
    @names_css = params[:names_css] || nil
    @names = params[:names] || nil
    @comments = params[:comments] || []
    @main_html = @html if params[:html]
    self.html = params[:html] || @html unless @is_browser
    @html = params[:html] if @is_browser && params[:html]
    @downcase = params[:downcase] || false
    @range = params[:range] || (0..-1)
    @attribute = params[:attribute] || 'href'
    @child = params[:child] || nil
    @url_prefix = params[:url_prefix] || ""
    @clean = params[:clean] || true
    @is_datetime = params[:is_datetime] || nil
  end

  # first values == default
  # params[:css]                - nil                                      # needed values in css
  # params[:type]               - 'text' / 'link' /'date' / 'html' / 'teaser' / 'time'
  # params[:names_css]          - nil                                      # css to take values by their names, use with css
  # params[:names]              - nil / ['Name', 'Phone']                  # use names_css
  # params[:comments]           - nil / ['<!-- case caption -->', ...]     # take values after comments in html code
  # params[:html]               - @html / @html.css('div.custom-contentTypeBlock')[-2]
  # params[:downcase]           - false  / true
  # params[:range]              - 0..-1 / [0..1, 3..-1] / -1 / 0
  # params[:attribute]          - 'href' / 'value' / 'option' / 'on_click'
  # params[:url_prefix]         - "" / "https://www.google.com"
  # params[:clean]              - true / false
  # params[:child]              - nil / 0
  def elements_list(**params)
    set_params(**params)

    return [] if html.blank?

    return table_values_by_names_and_css if @names_css && @names

    data = html.css(@css)&.map.with_index do |elem, index|
      elem = elem.children[@child] if @child
      case @type
      when 'text' # TODO change attribute func for browser
        elem = @attribute != 'href' ? elem.attribute(@attribute).text : elem.text # TODO TEST CGI.unescapeHTML(elem.text)
      when 'html'
        elem = elem.to_html.to_s
      when 'link'
        # TODO TEST elem = elem.url(@attribute) with using nikkou gem
        elem = @converter.string_to_link(elem[@attribute].to_s, @url_prefix)
      when 'date'
        elem = @converter.string_to_date(elem.text, nil, @is_datetime)
      when 'time'
        elem = @converter.string_to_time(elem.text)
      when 'teaser'
        @dirty_news[index] = 1
        next unless @lang_tag && @lang_tag.include?("en")
        next if elem.text.to_s.empty?
        @dirty_news[index] = 0
        elem = @converter.article_to_teaser(elem)
      else
        return
      end
      elem = elem&.downcase if @downcase
      elem = @converter.clean_string(elem) if @clean
      elem
    end
    @html = @main_html if @main_html
    @range.is_a?(Array) ? @range.map { |range| data[range] }.flatten : data[@range]
  end

  def table_values_by_names_and_css
    @names.compact!
    names_values = []
    html.css(@names_css).each_with_index do |row, i|
      if @names.include?(row.text)
        index = @names.index(row.text)
        names_values[index] ||= ""
        names_values[index] += "#{@converter.clean_string(html.css(@css)[i].text)}, "
      end
    end
    names_values.map do |elem|
      elem.to_s.split(", ").reject(&:blank?).join(', ')
    end
  end

  def values_after_comments(data, arr_comments, border = nil)
    values = arr_comments.map.with_index do |comment, index|
      if arr_comments[index + 1].blank?
        data.split(comment).last
      else
        data.split(comment).last.split(arr_comments[index + 1]).first
      end
    end
    values[-1] = values[-1]&.split(border)&.first if border && values[-1]&.include?(border)
    values
  end

  def find_unique_rows(html_arr, css)
    unique_columns = []
    html_arr.each do |html|
      Nokogiri::HTML(html[0]).css(css).map do |row|
        unique_columns << row.text unless unique_columns.include?(row.text)
      end
    end
    unique_columns
  end

  def nokogiri_search_by_text(html = @html, text)
    html.at(":contains('#{text}'):not(:has(:contains('#{text}')))")
  end

  # [...document.querySelectorAll("table.FormTable tr.OddRow")].href;
  # [...document.querySelectorAll("table.FormTable tr.OddRow")].map(x => x.href);
  # [].map.call(document.querySelectorAll('table.FormTable tr.OddRow td a'), function(e) { return e.href; });
  def absolute_url_list(browser, css)
    browser.evaluate <<~JS
    [].map.call(document.querySelectorAll('#{css}'), function(e) { return e.href; });
    JS
  end

  def mouseover(browser, css, index) #.slice(#{from}, #{to})
    browser.evaluate <<~JS
    document.querySelectorAll('#{css}')[#{index}].dispatchEvent(new MouseEvent('mouseover', {
      'view': window,
      'bubbles': true,
      'cancelable': true
    }));
    JS
  end
end