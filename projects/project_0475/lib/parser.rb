# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_links(source)
    page = Nokogiri::HTML source.body
    page.css('a.member-name').map { |el| URL + el.attributes["href"].value }
  end

  def next?(source)
    page = Nokogiri::HTML source.body
    !page.css('li.next-page').empty?
  end

  def need_to_swap?(first, middle)
    flag = first.size == 1 || first.size == 2 && first[1] == '.'
    flag &&= middle.size > 2
    flag &&= !(middle.size == 4 && middle[-1] == '.')
  end

  def get_data_from_list(list)
    dt = list.css('dt').map(&:to_s)
    dd = list.css('dd').map(&:to_s).map { |el| el.gsub('&amp;', '&') }
    index = 0
    # ПЕРЕДЕЛАТЬ, чтобы брал следующий
    !!dt[index] && dt[index].include?('class="address"') ? index += 1 : dd.insert(0, '<dd></dd>')
    !!dt[index] && dt[index].include?('class="website"') ? index +=1 : dd.insert(1, '<dd></dd>')
    !!dt[index] && dt[index].include?('class="email"') ? index +=1 : dd.insert(2, '<dd></dd>')
    !!dt[index] && dt[index].include?('class="phone"') ? index +=1 : dd.insert(3, '<dd></dd>')
    !!dt[index] && dt[index].include?('class="fax"') ? index +=1 : dd.insert(4, '<dd></dd>')
    !!dt[index] && dt[index].include?('Areas:</dt>') ? index +=1 : dd.insert(5, '<dd></dd>')
    !!dt[index] && dt[index].include?('Languages:</dt>') ? index +=1 : dd.insert(6, '<dd></dd>')
    !!dt[index] && dt[index].include?('School:</dt>') ? index +=1 : dd.insert(7, '<dd></dd>')
    !!dt[index] && dt[index].include?('Admission:</dt>') ? index +=1 : dd.insert(8, '<dd></dd>')
    !!dt[index] && dt[index].include?('Class:</dt>') ? index +=1 : dd.insert(9, '<dd></dd>')
    !!dt[index] && dt[index].include?('Status:</dt>') ? index +=1 : dd.insert(10, '<dd></dd>')
    dd
  end

  def parse_member(source)
    page = Nokogiri::HTML source.body
    member_name = page.css('.member-name').text
    suffixes = []
    name_split = member_name.split
    while %w(. ,).include?(name_split[-1][-1]) ||
          ('0'..'9').include?(name_split[-1][-1]) ||
          %w(II III IV V VI).include?(name_split[-1]) do
      suffixes.prepend(name_split[-1])
      name_split.pop
    end
    f_name = name_split[0]
    l_name = name_split[-1]
    m_name = name_split[1..-2].join(' ')
    [f_name, l_name, m_name].each { |el| el[0] = el[0].upcase if !!el && !!el[0] }
    f_name, m_name = m_name, f_name if need_to_swap?(f_name, m_name)
    suff = suffixes.join(' ')

    job_title = page.css('.job-title').text
    org_name = page.css('.organization-name').text

    list = page.css('.listed-info')
    dt = list.css('dt').map(&:to_s)
    dd = get_data_from_list(list)

    addr_block = dd[0][4..-6].split('<br>')
    addr_block.insert(1, '') if addr_block.size < 4
    address = addr_block[0..1].join(" ").strip
    split_block = addr_block[2].split(',') if !!addr_block[2]
    city = split_block[0] if !!split_block
    state = split_block[1].split[0] if !!split_block && !!split_block[1]
    zip = split_block[1].split[1] if !!split_block && !!split_block[1]
    county = addr_block[3]

    website = dd[1][4..-6].split('>')[1].split('<')[0] if !dd[1][4..-6].empty?
    dd2 = dd[2].split('"')
    email = "#{dd2[5]}@#{dd2[7]}"
    email = '' if email == '@'
    phone = dd[3][4..-6].strip.gsub(/ +/, ' ')
    fax = dd[4][4..-6].strip.gsub(/ +/, ' ')

    prac = dd[5][4..-6]
    lang = dd[6][4..-6]
    school = dd[7].split[2..-2].join(' ') if !dd[7][4..-6].empty?
    date = Date.strptime(dd[8][4..-6], '%m/%d/%Y') if !dd[8][4..-6].empty?
    type = dd[9][4..-6]
    status = dd[10][4..-6]

    url = source.env.url.to_s
    bar = url.split('/')[-1]
    record_data = {
      bar:      bar,
      name:     member_name,
      f_name:   f_name,
      l_name:   l_name,
      m_name:   m_name,
      date:     date,
      status:   status,
      type:     type,
      phone:    phone,
      email:    email,
      fax:      fax,
      org:      org_name,
      addr:     address,
      zip:      zip,
      city:     city,
      state:    state,
      county:   county,
      school:   school,
      web:      website,
      md5_hash: '',
      url:      url,
      suff:     suff,
      job:      job_title,
      prac:     prac,
      lang:     lang
    }
    digest_data = {
      bar:      bar,
      name:     member_name,
      date:     date,
      status:   type,
      type:     status,
      phone:    phone,
      email:    email.empty? ? '@' : email,
      fax:      fax,
      org:      org_name,
      addr:     address,
      zip:      zip,
      city:     city,
      state:    state,
      county:   county,
      school:   school,
      web:      website
    }
    str = ""
    digest_data.each { |field| str += field.to_s if !!field }
    digest = Digest::MD5.new.hexdigest(str)
    record_data[:md5_hash] = digest
    record_data # return single record data
  end
end
