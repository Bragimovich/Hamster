# frozen_string_literal: true

class Normalizer < Hamster::Parser
  SPACES = ' ' * 3

  # remove lines without any text_digit information
  #   and
  # remove leading and trailng whitespaces
  def final_cutting(lines)
    lines.select {|el| el =~ /[0-9a-zA-Z]/}.map(&:strip)
  end

  def pdf_with_parenthese_or_pipe(lines)
    # 1. calculate the position of ')'
    symbol_positions = lines.map {|el| el.index(')') || el.index('|')}.compact.sort
    pos = symbol_positions[symbol_positions.size.div(2)]
    # 2. remove all after ')' with ')' itself
    lines.map! {|el| el[0, pos]}
    final_cutting(lines)
  end

  def pdf_with_two_columns(lines)
    gap_end_pos = lines.map {|el| (el.size - el.reverse.index('  ')) rescue 0 }.sort
    gap_end_pos.reject! {|el| el < 30}

    distance = (gap_end_pos[1] - gap_end_pos[0] rescue 0)
    gap_end_pos.shift if distance > 10
    pos = gap_end_pos.first

    lines.map! {|el| el[0, pos]} unless pos.nil?
    final_cutting(lines)
  end

  def other_pdf(lines)
    final_cutting(lines)
  end

  def attorneys_gapped(lines)
    # pp lines
    # 1. align text to left side, move leading spaces into gap (if exists), keep unaligned if no gap
    lines.each do |line|
      leading_size = line.size - line.lstrip.size
      gap_pos = line.index(SPACES, leading_size)
      line.insert(gap_pos, ' ' * leading_size).lstrip! unless gap_pos.nil?
    end
    # 2. calculate spaces by index
    gap_end_pos = lines.map {|el| (el.size - el.reverse.index('  ')) rescue 0 }
    last_gap_index = (gap_end_pos.size.pred - gap_end_pos.reverse.find_index {|el| el > 33} rescue nil)
    return lines if last_gap_index.nil?

    cut_position = gap_end_pos.select {|el| el > 33}.sort.first
    # 3. separate left column
    gapped_lines = lines[0..last_gap_index]
    # pp gapped_lines.map {|line| "#{line[0,cut_position]}|#{line[cut_position..]}"}
    res = atty_left_column(gapped_lines, cut_position) +
          lines[last_gap_index.next..] +
          atty_right_column(gapped_lines, cut_position)
    res.reject! {|line| line.size < 5 || dirty_data?(line)}

    final_cutting(res.select {|el| el.size > 5})
  end

  def dirty_data?(str)
    str.delete(' ').size.div(str.scan(/\w/).size) > 2 rescue true
  end

  def atty_left_column(lines, pos)
    lines.map {|line| !line[0,pos][-3,3].eql?("   ") && line[pos..]&.size.to_i < 10 ? line : line[0, pos]} # escaping nil
  end

  def atty_right_column(lines, pos)
    lines.map {|line| !line[0,pos][-3,3].eql?("   ") && line[pos..]&.size.to_i < 10 ? nil : line[pos..]}.compact # escaping nil
  end

  def attorneys_not_gapped(lines)
    lines
    # 1. remove leading lines
  end
end
