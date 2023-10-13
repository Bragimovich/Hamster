# frozen_string_literal: true
require 'pdf-reader'

class Parser < Hamster::Parser

  def initialize()
    super
  end

  def parse_pdf_page(page)

    remove_text = '* The HRC Foundation’s “Best Places to Work” distinction helps the public understand a company’s '       \
          'commitment to inclusive policies and practices for '                                                             \
          'LGBTQ+ workers. Given ongoing concerns about and the extent of litigation against regarding workplace equality ' \
          'and safety for women and the LGBTQ+ community, HRC has suspended the company’s Corporate Equality Index score '  \
          'and will not be rewarding it with a “Best Places to Work” distinction in the 2022 CEI. HRC and '                 \
          'have had productive conversations about work- place policies and prac- tices that will ensure that its '         \
          'workplace is continuing to improve in the areas of workplace equality, inclu- sion and safety. ' +

          'The HRC Foundation’s “Best Places to Work” distinction helps the public understand a company’s commitment to inclusive '         \
          'policies and practices for LGBTQ+ workers. Given the harm experienced by transgender workers at as a result of the '             \
          'company’s handling of the release of The Closer, HRC has suspended Net- Corporate Equality Index score and will not be '         \
          'rewarding it with a “Best Places to Work” distinc- tion in the 2022 CEI. HRC and are having productive conversations '           \
          'about steps the company could take to demonstrate it is acting in a manner consistent with the values of workplace equality and' \
          'inclusion and to improve trust among their employ-ees and the public'

    remove_words = remove_text.split

    data = []

    page.text.each_line do |line|

      array_line = line.lstrip.split(/\s{2,}/, 4)

      if array_line.length >= 4 and array_line[-1].count(' ') > 10
        last_element = array_line.pop
        array_line += last_element.split(/\s{2,}/, 2)
      end

      if array_line.length >= 4
        array_line[0] = array_line[0].split.delete_if{ |word| remove_words.include?(word) }.join(' ')

        array_line[0] = array_line[0].gsub(/publicive/i, 'Adaptive')
        array_line[0] = array_line[0].gsub(/distinc-flac/i, 'Aflac')
        array_line[0] = array_line[0].gsub(/prac-IG/i, 'AIG')
        array_line[0] = array_line[0].gsub(/areasAir/i, 'Air')

        array_line[0] = array_line[0].gsub(/Closer,ell/i, 'Newell')
        array_line[0] = array_line[0].gsub(/beont/i, 'Newmont')
        array_line[0] = array_line[0].gsub(/distinc-ews/i, 'News')
        array_line[0] = array_line[0].gsub(/HNextEra/i, 'NextEra')
        array_line[0] = array_line[0].gsub(/conversationNextGen/i, 'NextGen')
        array_line[0] = array_line[0].gsub(/demonstrateP/i, 'NFP')
        array_line[0] = array_line[0].gsub(/manneNGL/i, 'NGL')
        array_line[0] = array_line[0].gsub(/aNielsen/i, 'Nielsen')
        array_line[0] = array_line[0].gsub(/employ-elsenIQ/i, 'NielsenIQ')

        if array_line[0] == "Netflix York Times Co." then array_line[0] = array_line[0].gsub(/Netflix/i, 'New') end
      end

      if array_line.length >= 4 then data.push(array_line.reject(&:empty?)) end

    end

    return data

  end

  def parse_rating_data(line)

    arr_line = line.chomp!.split(/\s+/)

    if arr_line.size == 1
      return [arr_line[0] == '*' ? nil : arr_line[0].to_i, nil, nil]
    end

    if arr_line.size == 3
      return [arr_line[0] == '*' ? nil : arr_line[0].to_i, arr_line[1].to_i, arr_line[2].to_i]
    end

    if arr_line.size == 2
      if line.count(' ').between?(2, 5)
        return [arr_line[0] == '*' ? nil : arr_line[0].to_i, arr_line[1].to_i, nil]
      else
        return [arr_line[0] == '*' ? nil : arr_line[0].to_i, nil, arr_line[1].to_i]
      end
    end

  end
end
