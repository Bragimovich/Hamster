# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_app_config(html)
    doc     = Nokogiri::HTML(html)
    cfg_txt = doc.xpath('//textarea[@id="tsConfigContainer"]').first&.inner_text

    if cfg_txt.nil?
      logger.info 'Failed to parse app config.'
      logger.info html
      raise 'Failed to parse app config.'
    end

    parse_json(cfg_txt)
  end

  def parse_boot_info(body)
    body  = body.gsub(/(Datastore"\s*:\s*")[0-9a-fA-F]{4,}(")/, '\1...\2')
    body1 = body.gsub(/(^|\})\s*\d+;\s*(\{|$)/, '\1(((SPLITTER_BY_SIZE)))\2')
    jsons = body1.split('(((SPLITTER_BY_SIZE)))').reject(&:blank?)
    jsons = jsons.map { |json| parse_json(json) }
    json1 = jsons.first

    zones = json1.dig('worldUpdate', 'applicationPresModel', 'workbookPresModel', 'dashboardPresModel', 'zones')
    if zones.nil? || zones.size.zero?
      logger.info 'Failed to parse bootstraped session.'
      logger.info body
      raise 'Failed to parse bootstraped session.'
    end

    page_param   = nil
    agcy_param   = nil
    zones.each do |_, zone|
      zone_type = zone.dig('zoneCommon', 'zoneType')
      zone_name = zone.dig('zoneCommon', 'name')

      if zone_type == 'paramctrl' && zone_name == 'Page Number'
        page_param = zone.dig('presModelHolder', 'parameterControl', 'parameterName')
      end

      if zone_type == 'paramctrl' && zone_name == 'Agency:'
        agcy_param = zone.dig('presModelHolder', 'parameterControl', 'parameterName')
      end
    end

    res = {
      page_param:   page_param,
      agcy_param:   agcy_param,
    }

    if res.any? { |_, v| v.blank? }
      logger.info 'Failed to parse bootstraped session. (data missing)'
      logger.info body
      raise 'Failed to parse bootstraped session. (data missing)'
    end

    json2 = jsons[1]
    return res if json2.blank?

    data_segs = json2.dig('secondaryInfo', 'presModelMap', 'dataDictionary', 'presModelHolder', 'genDataDictionaryPresModel', 'dataSegments')
    return res if data_segs.nil?

    data_segs.each do |k, v|
      store_data_segment(k, v)
    end

    res
  end

  def parse_op_result(body, ensure_total_pages = false)
    body = body.gsub(/(Datastore"\s*:\s*")[0-9a-fA-F]{4,}(")/, '\1...\2')
    json = parse_json(body)

    data_segs = json.dig('vqlCmdResponse', 'layoutStatus', 'applicationPresModel', 'dataDictionary', 'dataSegments')
    unless data_segs.nil?
      data_segs.each do |k, v|
        store_data_segment(k, v)
      end
    end

    zones = json.dig('vqlCmdResponse', 'layoutStatus', 'applicationPresModel', 'workbookPresModel', 'dashboardPresModel', 'zones')
    if zones.nil? || zones.size.zero?
      logger.info 'Failed to parse page data. (zones)'
      logger.info body
      raise 'Failed to parse page data. (zones)'
    end

    curr_page   = nil
    total_pages = nil
    first_names = []
    last_names  = []
    agencies    = []
    statuses    = []
    salaries    = []
    zones.each do |_, zone|
      zone_name = zone['worksheet']
      next unless ['Table', 'Last Page', 'Last Page (2)'].include?(zone_name)

      pane_cols_data = zone.dig('presModelHolder', 'visual', 'vizData', 'paneColumnsData')
      next if pane_cols_data.nil?

      data_indices = pane_cols_data.dig('paneColumnsList', 0, 'vizPaneColumns')
      next if data_indices.nil?

      data_indices = data_indices.map do |idx|
        idx['valueIndices'].presence || idx['aliasIndices'].presence || []
      end

      viz_data_cols = pane_cols_data['vizDataColumns']
      next if viz_data_cols.nil?

      viz_data_cols.each do |viz_col|
        indices = data_indices[viz_col['columnIndices'][0]]

        case viz_col['fieldCaption']
        when 'Agency'
          agencies = indices.map { |idx| pick_string_value(idx) } if zone_name == 'Table'
        when 'First Name'
          first_names = indices.map { |idx| pick_string_value(idx) } if zone_name == 'Table'
        when 'Last Name'
          last_names = indices.map { |idx| pick_string_value(idx) } if zone_name == 'Table'
        when 'Status'
          statuses = indices.map { |idx| pick_string_value(idx) } if zone_name == 'Table'
        when 'SUM(Salary)'
          salaries = indices.map { |idx| pick_real_value(idx) } if zone_name == 'Table'
        when 'AGG(LastPage)'
          total_pages = pick_integer_value(indices[0]) if zone_name == 'Last Page'
        when 'Page Number'
          curr_page = pick_integer_value(indices[0]) if zone_name == 'Last Page (2)'
        end
      end
    end

    data_error   = curr_page.nil?
    data_error ||= total_pages.nil? if ensure_total_pages
    data_error ||= first_names.blank?
    data_error ||= last_names.blank?
    data_error ||= agencies.blank?
    data_error ||= statuses.blank?
    data_error ||= salaries.blank?

    if data_error
      logger.info 'Failed to parse page data. (data cols)'
      logger.info body
      raise 'Failed to parse page data. (data cols)'
    end

    data = []
    salaries.each_with_index do |sal, idx|
      data << {
        first_name: first_names[idx],
        last_name:  last_names[idx],
        agency:     agencies[idx],
        status:     statuses[idx],
        salary:     sal
      }
    end

    [curr_page, total_pages, data]
  end

  private

  def parse_date(date_string)
    dt = Date.strptime(date_string, '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil
    dt ||= Date.strptime(date_string, '%m/%d/%Y').strftime('%Y-%m-%d') rescue nil
    dt
  end

  def parse_json(json)
    JSON.parse(json)
  rescue => e
    logger.info 'Failed to parse JSON.'
    logger.info json
    raise e
  end

  def pick_integer_value(idx)
    return nil if @intg_vals.nil?
    @intg_vals[idx]
  end

  def pick_real_value(idx)
    return nil if @real_vals.nil?
    @real_vals[idx]
  end

  def pick_string_value(idx)
    return nil if @cstr_vals.nil?
    @cstr_vals[idx]
  end

  def store_data_segment(idx, data_seg)
    return if idx.nil?

    @data_segments ||= {}
    @data_segments[idx] = data_seg

    @intg_vals = []
    @real_vals = []
    @cstr_vals = []

    @data_segments.sort_by { |k, _| k.to_i }.each do |_, data_seg|
      next if data_seg.nil?

      data_cols = data_seg['dataColumns']
      next if data_cols.nil?

      ivals       = data_cols.find { |seg| seg['dataType'] == 'integer' }
      ivals       = ivals['dataValues'] unless ivals.nil?
      @intg_vals += ivals unless ivals.nil?
      rvals       = data_cols.find { |seg| seg['dataType'] == 'real' }
      rvals       = rvals['dataValues'] unless rvals.nil?
      @real_vals += rvals unless rvals.nil?
      svals       = data_cols.find { |seg| seg['dataType'] == 'cstring' }
      svals       = svals['dataValues'] unless svals.nil?
      @cstr_vals += svals unless svals.nil?
    end
  end
end
