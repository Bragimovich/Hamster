require 'nokogiri'
require 'erb'
require_relative '../models/illinois'
require_relative '../models/illinois_tmp'

class Store < Hamster::Parser

  def initialize(run_id)
    super
    @run_id = run_id
    @list_contact = []
    @root_dir = "projects/project_%04d/" % 124
    @sql_tmpl_dir = @root_dir + "sql_tmpl/"
  end

  def parse

    @folder = "layers"
    list_letters = peon.list(subfolder: @folder)
    thread = []
    list_letters.each do |letter|

      thread << Thread.new(letter) do |letter|

        folder = @folder + "/" + letter
        files = peon.list(subfolder: folder)
        files.each do |file|
          begin
            content = peon.give(file: file, subfolder: folder)
            @file_debug = folder + "/" + file
            hash_content = parse_lawyers content
            if !hash_content.nil?
              begin
                save_to_db hash_content
                # peon.move(from: folder, to: folder, file: file)
              rescue StandardError => error
                if error.to_s.match?(/Duplicate entry/)
                  peon.move(from: folder, to: "duplicate/" + folder, file: file)
                else
                  peon.move(from: folder, to: "error/" + folder, file: file)
                end
              end
            else
              raise "Error: Content 'hash_content' nil"
            end
          rescue StandardError => error_store
            puts error_store.to_s.red
            puts file + " - " + folder
          end
        end
      end
    end

    thread.each(&:join)

    # set_delete_flag
  end

  def parse_lawyers content

    html = Nokogiri::HTML(content)
    full_licensed_name = html.css("[for=\"FullLicensedName\"]").first.parent.css("div").text.squish
    full_former_name = html.css("[for=\"FullFormerNames\"]").first.parent.css("div").text.squish
    registered_address = html.css("[for=\"BusinessAddress\"]").first.parent.css("div").first.css("div")

    law_firm__arr = (registered_address.size > 0) ? registered_address[1..-1].map { |item| item.text.squish } : nil

    link_page = (html.css("a.printable-button").attr("href").value) if !html.css("a.printable-button").attr("href").nil?
    link_page = ("https://www.iardc.org" + link_page) if !link_page.nil?
    uuid = link_page.split('/').last

    law_firm_name = ''
    law_firm_address = ''
    law_firm_city_state_zip = ''

    if !law_firm__arr.nil? and law_firm__arr.size > 0
      law_firm_name = (law_firm__arr[-3].nil?) ? '' : law_firm__arr[-3]
      law_firm_address = (law_firm__arr[-2].nil?) ? '' : law_firm__arr[-2]
      law_firm_city_state_zip = (law_firm__arr[-1].nil?) ? '' : law_firm__arr[-1]
    end

    date_admitted = nil
    registration_status = nil
    registered_phone = html.css("[for=\"BusinessPhone\"]").first.parent.css("div").text.squish
    html.css("div.lawyer-body-group div").each do |item|
      if item.text.squish.match?(/Date Admitted/) and date_admitted.nil?
        date_admitted = item.css("p").last.text.squish
      end

      if item.text.squish.match? /Illinois\s+Registration\s+Status/ and registration_status.nil?
        registration_status = item.css("p").last.text.squish

        if registration_status.match? /None/
          registration_status = ''
        elsif registration_status.nil?
          registration_status = ''
        end
      end
    end
    md5_hash = full_licensed_name + law_firm__arr.join + link_page.to_s + registered_phone.to_s + date_admitted.to_s + registration_status + registered_address.to_s.squish
    md5_hash = Digest::MD5.hexdigest md5_hash

    {
      run_id: @run_id,
      name: full_licensed_name,
      former_names: (full_former_name.match?(/^None/)) ? '' : full_former_name,
      law_firm_name: law_firm_name,
      law_firm_address: law_firm_address,
      law_firm_city_state_zip: law_firm_city_state_zip,
      phone: (!registered_phone.nil? and !registered_phone.match?(/^Not available/)) ? registered_phone : '',
      date_admitted: (!date_admitted.nil? and !date_admitted.empty?) ? Date.parse(date_admitted) : '',
      registration_status_raw: registration_status.to_s.squish,
      data_source_url: link_page.to_s,
      touched_run_id: @run_id,
      md5_hash: md5_hash,
      uuid: uuid
    }
  end

  def save_to_db hash_data
    if !!Illinois.find_by(md5_hash: hash_data[:md5_hash])
      rec = Illinois.find_by(md5_hash: hash_data[:md5_hash])
      rec.touched_run_id = @run_id
      rec.save
    else
      rec = Illinois.find_by(uuid: hash_data[:uuid])
      rec.name = hash_data[:name]
      rec.law_firm_name = hash_data[:law_firm_name]
      rec.law_firm_address = hash_data[:law_firm_address]
      rec.law_firm_city_state_zip = hash_data[:law_firm_city_state_zip]
      rec.phone = hash_data[:phone]
      rec.registration_status_raw = hash_data[:registration_status_raw]
      rec.data_source_url = hash_data[:data_source_url]
      rec.touched_run_id = hash_data[:touched_run_id]
      rec.md5_hash = hash_data[:md5_hash]
      rec.save
    end
  end

  def set_delete_flag
    # Illinois.where("touched_run_id <> ? AND deleted = ?", @run_id, 0).update_all(deleted: 1)
  end

  def parse_store_index content
    page = Nokogiri::HTML(content)

    return false if page.css("div table tr").first.nil?

    page.css("div table tr").first.remove
    list_tr = page.css("div table tr")
    list_tr.each do |item|
      td = item.css("td")
      uuid = td[0].text.squish
      name = td[1].text.squish
      date_admitted = (!td[5].text.squish.blank?) ? Date.strptime(td[5].text.squish, '%m/%d/%Y') : ""
      city = td[3].text.squish
      state = td[4].text.squish
      authorized_to_practice = td[6].text.squish
      former_names = td[2].text.squish

      if (rec = Illinois.find_by(uuid: uuid, md5_hash: nil)).nil?
        obj = {
          run_id: @run_id,
          uuid: uuid,
          name: name,
          date_admitted: date_admitted,
          city: city,
          state: state,
          authorized_to_practice: authorized_to_practice,
          former_names: former_names,
          touched_run_id: @run_id
        }
        rec = Illinois.new(obj)
        rec.save
      else

        date_base = (!rec.date_admitted.to_s.blank?) ? rec.date_admitted.strftime("%Y-%m-%d") : ""
        date_date = date_admitted.to_s
        str_src_in_base = rec.name.to_s + rec.uuid + date_base.to_s + rec.city.to_s + rec.state.to_s + rec.authorized_to_practice.to_s + rec.former_names.to_s
        str_src_in_data = name + uuid + date_date + city + state + authorized_to_practice + former_names
        from_base = Digest::MD5.hexdigest str_src_in_base
        from_site = Digest::MD5.hexdigest str_src_in_data

        if (from_base === from_site)
          rec.touched_run_id = @run_id
          rec.save
        else
          rec.md5_hash = from_base
          rec.save

          obj = {
            run_id: @run_id,
            uuid: uuid,
            name: name,
            date_admitted: date_admitted,
            city: city,
            state: state,
            authorized_to_practice: authorized_to_practice,
            former_names: former_names,
            touched_run_id: @run_id
          }
          rec = Illinois.new(obj)
          rec.save
        end
      end

    end
  end

  def index_uuid(run_id = nil)
    Illinois.select('MAX(id) AS `id`, uuid, COUNT(id) AS id_count').where("md5_hash IS NULL").group("uuid") if run_id.nil?
    Illinois.select('MAX(id) AS `id`, uuid, COUNT(id) AS id_count').where("run_id = #{run_id}").group("uuid") unless run_id.nil?

  end

  def move_to_main_table

    update_erb_tmpl = @sql_tmpl_dir + "update.erb"
    text_tmpl = File.open(update_erb_tmpl).read
    tmpl_erb = ERB.new(text_tmpl)
    sql = tmpl_erb.result(instance_eval { binding })
    queries = sql.split(';')
    queries.each do |query|
      query.strip!
      Illinois.connection.execute(query) unless query.empty?
    end
  end

end
