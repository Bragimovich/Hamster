# frozen_string_literal: true

class Keyword
  def self.next(keyword = nil)
    return 'aaaa' if keyword.nil?
    new_keyword = keyword.dup
    last = keyword.size - 1
    while last >= 0 && keyword[last] == 'z'
      new_keyword[last] = 'a'
      last -= 1
    end
    return new_keyword if last < 0
    new_keyword[last] = (keyword[last].ord + 1).chr
    return new_keyword
  end
end
