# frozen_string_literal: true

require_relative 'pdf_text_run'

class PDFReceiver < PDF::Reader::PageTextReceiver
  attr_reader :logger

  HEADER_TITLES = {
    agency:         ['Agency Name', 'Office'],
    annual_salary:  ['Compensation', 'Annual Rate', 'Annual Rt', 'Comp Rate', 'Comp Rt'],
    appt_type:      ['Type Appt', 'Type of Appt', 'Appointment Type'],
    first_name:     ['First Name'],
    hire_date:      ['Hire Date', 'Start Date'],
    last_name:      ['Last Name', 'Last'],
    position_title: ['Position Title', 'Job Title', 'Descr', 'Title'],
    grade:          ['Grade']
  }

  REPLACE_PATTERNS = {
    # "\xC3\xA9"     => 'e',
    # "\xC3\xB3"     => 'o',
    # "\xC3\x89"     => 'E',
    # "\xC3\x93"     => 'O',
    # "\xC3\xB1"     => 'n',
    # "\xC3\xAD"     => 'i',
    # "\xC3\xA1"     => 'a',
    # "\xC3\xBA"     => 'u',
    "\xC2\xA0"     => SPACE,
    "\xE2\x80\x90" => '-'
  }

  def initialize(logger = nil)
    @logger    = logger
    @order     = 0
    @curr_rect = nil
    @curr_clip = nil
    @last_char = nil
  end

  def append_rectangle(x, y, w, h)
    x2 = x + w
    y2 = y + h
    nx, ny = @state.ctm_transform(x, y)
    nx, ny = apply_rotation(nx, ny)
    nx2, ny2 = @state.ctm_transform(x2, y2)
    nx2, ny2 = apply_rotation(nx2, ny2)
    @curr_rect = PDF::Reader::Rectangle.new(nx, ny, nx2, ny2)
  end

  def page=(page)
    super(page)

    @order     = 0
    @curr_rect = nil
    @curr_clip = nil
    @last_char = nil
  end

  def parse_column_alignments(headers)
    detect_rows
    col_candidates = column_candidates
    detect_column_alignments(col_candidates, headers)
  end

  def parse_headers
    detect_rows
    col_candidates = column_candidates
    detect_headers(col_candidates)
  end

  def parse_data(headers, baselines)
    detect_rows
    extract_table_data(headers, baselines)
  end

  def restore_graphics_state
    super
    @curr_rect = nil
    @curr_clip = nil
  end

  def save_clipping_rect
    @curr_clip = @curr_rect
  end

  def set_clipping_path_with_nonzero
    save_clipping_rect
  end

  def set_clipping_path_with_even_odd
    save_clipping_rect
  end

  private

  def check_headers(row_text)
    txt = row_text.downcase.gsub(/ /, '')
    HEADER_TITLES.each do |_, header_titles|
      header_titles.each do |ht|
        txt = txt.gsub(ht.downcase.gsub(' ', ''), '')
      end
    end
    txt.strip == ''
  end

  def column_candidates
    avg_width =
      @characters
        .group_by { |ch| ch.font_size.to_i }
        .each_with_object({}) { |(fs, chs), hash| hash[fs] = chs.sum(0, &:width) / chs.size }

    @characters
      .group_by(&:row)
      .sort_by { |row, _| row }
      .map do |row_data|
        col_cands = []
        row       = row_data[0]
        chars     = row_data[1]

        chars
          .group_by { |ch| ch.y.to_i }
          .sort_by { |y, _| -y }
          .each do |line|
            line_chars = line[1].sort_by(&:x)
            line_chars.each_with_index do |ch, idx|
              last_cand = col_cands.last

              next_ch = line_chars[idx + 1]
              if ch.text == '$' && !next_ch.nil? && next_ch.text.match?(/^\d/)
                mergeable    = false
                insert_space = false
              else
                prev_ch = idx.zero? ? nil : line_chars[idx - 1]
                if ch.text.match?(/^\d/) && !prev_ch.nil? && prev_ch.text == '$' && !last_cand.nil?
                  mergeable    = true
                  insert_space = false
                else
                  unless last_cand.nil?
                    merge_rng =
                      Range.new(
                        last_cand[:end_x] - 3,
                        last_cand[:end_x] + avg_width[ch.font_size.to_i] * 1.1
                      )
                  end

                  mergeable = !last_cand.nil?
                  mergeable &&= last_cand[:font_size] == ch.font_size.round
                  mergeable &&= merge_rng.include?(ch.x)
                  mergeable &&= last_cand[:clipped] == !ch.clip_y.nil?

                  insert_space = mergeable && ch.x >= last_cand[:end_x] + avg_width[ch.font_size.to_i] * 0.3
                end
              end

              if mergeable
                if insert_space
                  last_cand[:text]  += ' '
                  last_cand[:break_pos] << last_cand[:end_x] << ch.x
                end

                last_cand[:text]  += ch.text
                last_cand[:end_x] = ch.x + ch.width
              else
                col_cands << {
                  break_pos: [],
                  clipped:   !ch.clip_y.nil?,
                  end_x:     ch.x + ch.width,
                  font_size: ch.font_size.round,
                  start_x:   ch.x,
                  text:      ch.text
                }
              end
            end
          end

        col_cands = split_numerical_cols(col_cands)

        # Merge clipped ones
        col_idx = 1
        while col_idx < col_cands.size
          col = col_cands[col_idx]
          overlap_col_idx =
            col_cands.find_index do |fcol|
              (col[:start_x] >= fcol[:start_x] && col[:start_x] < fcol[:end_x]) ||
              (col[:end_x] <= fcol[:end_x] && col[:end_x] > fcol[:start_x])
            end
          if overlap_col_idx.nil? || overlap_col_idx >= col_idx
            col_idx += 1
            next
          end

          col_cands[overlap_col_idx][:text]    += ' ' + col[:text]
          col_cands[overlap_col_idx][:start_x] = [col_cands[overlap_col_idx][:start_x], col[:start_x]].min
          col_cands[overlap_col_idx][:end_x]   = [col_cands[overlap_col_idx][:end_x], col[:end_x]].max
          col_cands[overlap_col_idx].delete(:break_pos)

          col_cands.delete_at(col_idx)
        end

        col_cands.sort_by { |cand| cand[:start_x] }
      end
  end

  def detect_column_alignments(col_candidates, headers)
    alignments = []
    col_candidates.each do |line|
      next if headers.size != line.size
      line.each_with_index do |col_cand, cand_idx|
        left   = col_cand[:start_x].to_i
        middle = (col_cand[:start_x] + (col_cand[:end_x] - col_cand[:start_x]) / 2.0).to_i
        right  = col_cand[:end_x].to_i

        left_idx =
          alignments.index do |al|
            al[:align] == :left && al[:pos] == left && al[:index] == cand_idx
          end

        if left_idx.nil?
          alignments << { align: :left, pos: left, count: 1, index: cand_idx }
        else
          alignments[left_idx][:count] += 1
        end

        middle_idx =
          alignments.index do |al|
            al[:align] == :middle && al[:pos] == middle && al[:index] == cand_idx
          end

        if middle_idx.nil?
          alignments << { align: :middle, pos: middle, count: 1, index: cand_idx }
        else
          alignments[middle_idx][:count] += 1
        end

        right_idx =
          alignments.index do |al|
            al[:align] == :right && al[:pos] == right && al[:index] == cand_idx
          end

        if right_idx.nil?
          alignments << { align: :right, pos: right, count: 1, index: cand_idx }
        else
          alignments[right_idx][:count] += 1
        end
      end
    end

    alignments
  end

  def detect_headers(col_candidates)
    headers_candidate = col_candidates.find do |cc|
      check_headers(cc.map { |cand| cand[:text] }.join(''))
    end

    return nil if headers_candidate.nil?

    get_headers(headers_candidate.map { |cand| cand[:text] }.join(''))
  end

  def detect_rows
    unclipped_lines =
      @characters
        .select { |ch| ch.clip_y.nil? }
        .group_by { |ch| ch.y.to_i }
        .sort_by { |y, _| -y }
    clipped_lines =
      @characters
        .reject { |ch| ch.clip_y.nil? }
        .group_by { |ch| ch.clip_y.to_i }
        .sort_by { |y, _| -y }

    clipped_lines.each do |line|
      ypos  = line[0]
      chars = line[1]

      line_idx = nil
      min_dist = nil
      unclipped_lines.each_with_index do |uc_line, uc_idx|
        distance = uc_line[0] - ypos
        if min_dist.nil? || distance.abs < min_dist.abs
          min_dist = distance
          line_idx = uc_idx
        end
      end

      if min_dist.nil?
        unclipped_lines.insert(0, [ypos, chars])
      elsif min_dist.abs > chars.first.font_size * 3 / 4
        unclipped_lines.insert(min_dist > 0 ? line_idx + 1 : line_idx, [ypos, chars])
      else
        unclipped_lines[line_idx][1] << chars
        unclipped_lines[line_idx][1] = unclipped_lines[line_idx][1].flatten
      end
    end

    row    = 0
    prev_y = nil
    unclipped_lines.each do |line|
      ypos  = line[0]
      chars = line[1]

      next_row = prev_y.nil?
      next_row ||= (ypos - prev_y).abs > 2
      row += 1 if next_row
      chars.each { |ch| ch.row = row }
      prev_y = ypos
    end
  end

  def extract_table_data(headers, baselines)
    avg_width =
      @characters
        .group_by { |ch| ch.font_size.to_i }
        .each_with_object({}) { |(fs, chs), hash| hash[fs] = chs.sum(0, &:width) / chs.size }

    @characters
      .group_by(&:row)
      .sort_by { |row, _| row }
      .map do |row_data|
        col_chars = {}
        chars =
          row_data[1].sort do |a, b|
            ydiff = b.y.to_i - a.y.to_i
            o = ydiff < -2 ? -1 : ydiff > 2 ? 1 : 0
            o = a.x <=> b.x if o.zero?
            o = a.order <=> b.order if o.zero?
            o
          end

        chars.each_with_index do |ch, idx|
          intersects = baselines.map do |bl|
            x1_max = [bl[:left], ch.x].max
            x2_min = [bl[:right], ch.x + ch.width].min
            x1_max > x2_min ? 0 : x2_min - x1_max
          end

          max_inter = intersects.max
          next if max_inter.zero?

          col_idx = intersects.find_index { |inter| inter == max_inter }
          next if col_idx.nil?

          col_chars[col_idx] = [] if col_chars[col_idx].nil?
          col_chars[col_idx] << ch
        end

        col_chars.each do |col_idx, col_chs|
          next if col_idx.zero? || col_chs.nil?

          extract_overlap_chars = Proc.new do |chs|
            chs.select do |ch|
              chs.any? do |fch|
                next false if fch.order == ch.order
  
                max_x  = [ch.x, fch.x].max
                min_x2 = [ch.x + ch.width, fch.x + fch.width].min
                max_y  = [ch.y, fch.y].max
                min_y2 = [ch.y + ch.font_size * 3 / 4, fch.y + fch.font_size * 3 / 4].min
                next false if min_x2 < max_x
                next false if min_y2 < max_y
                next false if min_x2 - max_x < avg_width[ch.font_size.to_i] * 0.2
                next false if min_y2 - max_y < [ch.font_size, fch.font_size].min * 3 / 4 * 0.2
  
                true
              end
            end
          end

          overlap_chars = extract_overlap_chars.call(col_chs)
          next if overlap_chars.size.zero?

          last_ch = nil
          col_chs.sort_by(&:order).each do |ch|
            break if !last_ch.nil? && ch.x < last_ch.endx - 3

            last_ch = ch
          end

          if last_ch.order == col_chs.max { |ch1, ch2| ch1.order <=> ch2.order }.order
            prev_col_chars = []
            this_col_chars = overlap_chars.sort_by(&:order)
            while this_col_chars.size > 0
              last_ch = this_col_chars.shift
              overlap_chars = extract_overlap_chars.call(this_col_chars)
              break if overlap_chars.size.zero?
            end
          end

          col_chars[col_idx - 1] = [] if col_chars[col_idx - 1].nil?
          col_chs.select { |ch| ch.order <= last_ch.order }.each { |ch| col_chars[col_idx - 1] << ch }
          col_chars[col_idx] = col_chs.select { |ch| ch.order > last_ch.order }
        end

        data = Hash[HEADER_TITLES.keys.map { |h| [h, nil] }]
        col_chars.each do |col_idx, col_chs|
          last_ch  = nil
          col_text = ''
          col_chs.each do |ch|
            if last_ch.nil?
              col_text = ch.text
              last_ch  = ch
              next
            end

            unless (last_ch.y - ch.y).abs <= 2 && ch.x < last_ch.endx + avg_width[ch.font_size.to_i] * 0.3
              col_text += ' ' unless last_ch.text == '$' && ch.text.match?(/^\d/)
            end
            col_text += ch.text
            last_ch  = ch
          end

          data[headers[col_idx]] = col_text
        end


        row_text = data.reduce('') { |str, (_, v)| str += (v || ''); str }
        next nil if check_headers(row_text)

        bad = data[:annual_salary].nil? || !data[:annual_salary].match?(/^\$?\d[\d,]*(?:\.[\d]+)?$/)
        bad ||= !data[:hire_date].nil? && !data[:hire_date].match?(/^\d{1,2}\/\d{1,2}\/\d{4}$|^\d{4}-\d{2}-\d{2}$/)
        bad ||= data[:first_name].nil? && data[:last_name].nil?
        bad ||= data.compact.keys.count < 2.0 / 3.0 * headers.count

        bad ? nil : data
      end
      .compact
  end

  def get_headers(row_text)
    txt = row_text.downcase.gsub(/ /, '')
    HEADER_TITLES.each do |header_key, header_titles|
      header_titles.each do |ht|
        txt = txt.gsub(ht.downcase.gsub(' ', ''), " #{HEADER_TITLES.keys.find_index(header_key)} ")
      end
    end
    txt.split(' ').reject(&:empty?).map { |idx| HEADER_TITLES.keys[idx.to_i] }
  end

  def internal_show_text(string)
    PDF::Reader::Error.validate_type_as_malformed(string, "string", String)
    if @state.current_font.nil?
      raise PDF::Reader::MalformedPDFError, "current font is invalid"
    end
    glyphs = @state.current_font.unpack(string)
    glyphs.each_with_index do |glyph_code, index|
      # paint the current glyph
      newx, newy = @state.trm_transform(0,0)
      newx, newy = apply_rotation(newx, newy)

      utf8_chars = @state.current_font.to_utf8(glyph_code)

      utf8_chars =
        REPLACE_PATTERNS.inject(utf8_chars) do |text, (pattern, replacement)|
          text.gsub(Regexp.new(pattern), replacement)
        end

      if utf8_chars.length != utf8_chars.bytes.length && !logger.nil?
        logger.info "Multi-byte character detected."
        logger.info "Glyph Code: #{glyph_code}, UTF-8 Chars: '#{utf8_chars}', Bytes: #{utf8_chars.bytes}"
      end

      # apply to glyph displacment for the current glyph so the next
      # glyph will appear in the correct position
      glyph_width = @state.current_font.glyph_width_in_text_space(glyph_code)
      th = 1
      scaled_glyph_width = glyph_width * @state.font_size * th
      unless utf8_chars == SPACE
        clipped = !@last_char.nil?
        clipped &&= !@last_char.clip_y.nil?
        clipped &&= @last_char.y.to_i == newy.to_i
        clipped &&= newx <= @last_char.endx + @last_char.width * 1.1

        unless @curr_clip.nil?
          chy1 = newy
          chy2 = newy + @state.font_size * 3 / 4
          cly1 = @curr_clip.bottom_left.y
          cly2 = @curr_clip.top_right.y
          clipped ||= chy1 < cly1
          clipped ||= chy2 > cly2
        end

        clip_y = @curr_clip&.bottom_left&.y || @last_char&.clip_y
        @last_char =
          PDFTextRun.new(
            newx,
            newy,
            scaled_glyph_width,
            @state.font_size,
            utf8_chars,
            clipped ? clip_y : nil,
            @order
          )
        @characters << @last_char
        @order += 1
      end
      @state.process_glyph_displacement(glyph_width, 0, utf8_chars == SPACE)
    end
  end

  def split_numerical_cols(col_cands)
    [
      /^\$?\d[\d,]+(?:\.[\d]+)?$/,
      /^\d{1,2}\/\d{1,2}\/\d{4}$|^\d{4}-\d{2}-\d{2}$/
    ].each do |regex|
      cand_idx = 0
      while (cand_idx < col_cands.size)
        cand = col_cands[cand_idx]
        if cand[:text].split(/ /).none? { |frag| frag.match?(regex) }
          cand_idx += 1
          next
        end

        frags = cand[:text].split(/ /)
        if frags.size <= 1
          cand_idx += 1
          next
        end

        c_idx = frags.find_index { |frag| frag.match?(regex) }

        prev_cand = c_idx > 0 ? {
          break_pos: c_idx >= 2 ? cand[:break_pos][0..((c_idx - 2) * 2 + 1)] : [],
          end_x:     cand[:break_pos][(c_idx - 1) * 2],
          start_x:   cand[:start_x],
          text:      frags[0..(c_idx - 1)].join(' ')
        } : nil

        matched_cand = {
          break_pos: [],
          end_x:     c_idx < frags.size - 1 ? cand[:break_pos][c_idx * 2] : cand[:end_x],
          start_x:   c_idx > 0 ? cand[:break_pos][(c_idx - 1) * 2 + 1] : cand[:start_x],
          text:      frags[c_idx]
        }

        next_cand = c_idx < frags.size - 1 ? {
          break_pos: c_idx < frags.size - 2 ? cand[:break_pos][((c_idx + 1) * 2)..((frags.size - 2) * 2 + 1)] : [],
          end_x:     cand[:end_x],
          start_x:   cand[:break_pos][c_idx * 2 + 1],
          text:      frags[(c_idx + 1)..(frags.size - 1)].join(' ')
        } : nil

        prev_cands = cand_idx > 0 ? col_cands[0..(cand_idx - 1)] : []
        next_cands = cand_idx < col_cands.length - 1 ? col_cands[(cand_idx + 1)..(col_cands.length - 1)] : []
        to_add     = [prev_cand, matched_cand, next_cand].compact
        col_cands  = [*prev_cands, *to_add, *next_cands]
      end
    end

    col_cands
  end
end
