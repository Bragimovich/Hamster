def add_commas(value, plus = false)
  parts = value.to_s.split('.')
  parts.first.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
  parts.delete_at(1) if parts[1].to_i.zero?
  parts = parts.join('.')
  parts = '+' + parts if plus && value > 0
  parts
end