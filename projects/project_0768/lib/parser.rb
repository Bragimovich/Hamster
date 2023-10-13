# frozen_string_literal: true

require_relative 'pdf_receiver'

class Parser < Hamster::Parser
  def parse_pdf_data(file_path)
    logger.info "Parsing PDF file - #{file_path}"

    pdf_file   = open(file_path)
    pdf_reader = PDF::Reader.new(pdf_file)
    receiver = PDFReceiver.new(logger)

    headers   = nil
    pdf_reader.pages.each do |pdf_page|
      pdf_page.walk(receiver)
      headers = receiver.parse_headers
      break unless headers.nil?
    end

    if headers.nil?
      logger.info 'Header info cannot be found.'
      logger.info "#{file_path}"
      return
    end

    baselines = extract_baselines(pdf_reader, receiver, headers)

    page_idx = 1
    page_cnt = pdf_reader.pages.size
    pdf_reader.pages.each do |pdf_page|
      logger.info "Page #{page_idx} of #{page_cnt}" if page_idx % ((page_cnt / 10).to_i) == 1
      pdf_page.walk(receiver)
      data =
        begin
          receiver.parse_data(headers, baselines)
        rescue StandardError => e
          logger.info 'Error occured while parsing PDF file.'
          logger.info "#{file_path} at Page #{page_idx}"
          logger.info e.full_message
          nil
        end

      data = data.each { |rec| rec[:page] = page_idx } unless data.nil?
      yield data if !data.nil? && block_given?

      page_idx += 1
    end
    logger.info "Parsed all #{page_cnt} pages"
  ensure
    pdf_file.close if defined?(pdf_file) && !pdf_file.nil?
  end

  def parse_pdf_links(html_body)
    text_downcase = "translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"
    href_downcase = "translate(@href, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"
    href_last4    = "substring(#{href_downcase}, string-length(#{href_downcase}) - 4 + 1, 4)"

    document = Nokogiri::HTML(html_body)
    link_els =
      document.xpath(
        "//a[contains(#{text_downcase}, 'public body employee information as of ')][#{href_last4} = '.pdf']"
      )

    link_els.map do |el|
      matches = /public body employee information as of (.*)$/i.match(el.text)
      next nil if matches.nil? || matches.size != 2

      report_date = Date.parse(matches[1]) rescue nil
      report_date = validate_date(report_date)
      [report_date, el.attributes['href'].value]
    end
    .compact
    .sort_by { |el| el[0] }
    .map { |el| [el[0]&.strftime('%Y-%m-%d'), el[1]] }
  end

  private

  def extract_baselines(pdf_reader, receiver, headers)
    page_indice = (0..(pdf_reader.pages.size - 1)).to_a.shuffle
    alignments  = []
    valid_pages = 0
    while valid_pages < 20 && page_indice.size > 0
      page_idx = page_indice.pop
      pdf_page = pdf_reader.pages[page_idx]
      pdf_page.walk(receiver)

      aligns = receiver.parse_column_alignments(headers)
      next if aligns.size < headers.size

      aligns.each do |align|
        alignment_idx =
          alignments.find_index do |a|
            a[:pos] == align[:pos] && a[:align] == align[:align] && a[:index] == align[:index]
          end

        if alignment_idx.nil?
          alignments << align
        else
          alignments[alignment_idx][:count] += align[:count]
        end
      end

      valid_pages += 1
    end

    alignments =
      alignments
        .group_by { |al| al[:index] }
        .sort_by { |key, _| key }
        .map { |al| al[1] }

    align_pos = { left: 0, right: 1, middle: 2 }
    base_lines = alignments.map do |al|
      base_line = al.sort_by { |ial| -ial[:count] * 10 + align_pos[ial[:align]] }.first
      { base_line[:align] => base_line[:pos] }
    end

    base_lines.each_with_index do |base_line, idx|
      base_line[:left] = 0 if idx.zero?
      base_line[:right] = pdf_reader.pages[0].width if idx == base_lines.size - 1
      next if idx.zero?

      prev_line = base_lines[idx - 1]
      unless base_line.key?(:left)
        if prev_line.key?(:right)
          base_line[:left] = prev_line[:right]
        else
          prev_min_right =
            alignments[idx - 1]
              .select { |al| al[:align] == :right }
              .map { |al| al[:pos] }
              .min

          base_line[:left] =
            alignments[idx]
              .select { |al| al[:align] == :left && al[:pos] > prev_min_right }
              .map { |al| al[:pos] }
              .min
        end
      end

      prev_line[:right] = base_line[:left] unless prev_line.key?(:right)
    end

    base_lines
  end

  def validate_date(date)
    return nil if date.nil?
    return nil unless date.instance_of?(Date)
    return nil if date.year < 1970 || date.year > 2069
    return nil if date.month < 1 || date.month > 12
    return nil if date.day < 1 || date.day > 31
    return nil unless Date.valid_date?(date.year, date.month, date.day)

    return date
  end
end
