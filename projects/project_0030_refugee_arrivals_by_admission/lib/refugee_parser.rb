# frozen_string_literal: true

class RefugeeParser < Hamster::Parser
  def initialize(content, content_type)
    super
    case content_type
    when :html
      @document = Nokogiri::HTML(content)
    when :pdf
      @document = PDF::Reader.new(content)
    end
  end
  
  def pdf_link
    @document&.css('#Admissions').css('a').map { |link| link['href'] }[1]
  end
  
  def table_marker=(marker)
    @table_marker = marker
  end
  
  def pdf_table
    report_start_date = nil
    report_end_date   = nil
    row_table         = []
    columns           = []
    
    @document.pages.each do |page|
      table_started = false
      mask          = nil
      
      page.text.split("\n").each do |line|
        next if line.empty?
        report_start_date, report_end_date = line.split(' through ') if line.match?(/through/)
        
        row           = []
        table_started = table_started ? !line.empty? && line[0].match?(/^ /) : line.match?(@table_marker)
        
        if table_started
          if line.match?(@table_marker)
            columns = line.split('  ').map { |part| part = part.strip; part.empty? ? nil : part }.compact
            mask    = line.sub(/^( +)/) { $1.gsub(/ /, '*') }.gsub(/( {2,})/, '\1|').split('|').map(&:size)
          else
            line = line.split('')
            
            mask.each_with_index do |length, index|
              row << [columns[index], line.shift(length).join.strip]
            end unless mask.nil?
            
            next if row[1][1].match?(/Grand Total/)
            
            row_table << row
            
            if row[1][1].match?(/Total/)
              row_table.insert -2, '---'
            end
          
          end
        
        end
      
      end
      
      row_table << '---'
    end
    
    group      = ''
    group_rows = []
    table      = []
    
    row_table.map do |row|
      if row == '---'
        rows = group_rows.map do |r|
          r[2][1] = group.split(',').join(', ').squeeze(' ')
          next if r[1][1].match?(/Total/) || r[1][1].empty?
          r.to_h
        end
        table << rows
        
        group      = ''
        group_rows = []
        next
      end
      
      group  += "#{row[0][1]} "
      months = row[2..5]
      
      next if row[1][1].match?(/total/i) || row[1][1].empty?
      
      months.each do |month|
        compressed_row = [
          [:report_start_date, report_start_date.squeeze(' ')],
          [:report_end_date, report_end_date.squeeze(' ')],
          [row[0][0].downcase.gsub(/ /, '_').to_sym, row[0][1]],
          [row[1][0].downcase.gsub(/ /, '_').to_sym, row[1][1]],
          [:month, month[0]],
          [:refugee_amount, month[1].to_i]
        ]
        group_rows << compressed_row
      end
    
    end
    
    table.flatten.compact
  end
  
end
