require_relative '../models/irs_non_profit__runs'
require_relative '../models/irs_non_profit__runs_forms_date'
require_relative '../models/irs_non_profit__forms_pub_78'
require_relative '../models/irs_non_profit__forms_990_n'
require_relative '../models/irs_non_profit__auto_revo_of_exemption_list'
require_relative '../models/irs_non_profit__forms_990_s'
require_relative '../models/irs_non_profit__orgs'

class IrsNonProfitKeeper
  def initialize
    @count = 0
    @run_id = run.run_id
  end

  attr_reader :run_id
  attr_accessor :count

  def status=(new_status)
    run.status = new_status
  end

  def status
    run.status
  end

  def finish
    run.finish
  end

  def last_data_source_update(form_type)
    IrsNonProfitRunsFormsDate.find_by(form_type: form_type)&.last_data_source_update
  end

  def update_last_scrape_date(form_type, date)
    IrsNonProfitRunsFormsDate.find_by(form_type: form_type)&.update(last_data_source_update: date)
  end

  def last_date
    IrsNonProfitForms990s.order(:return_fill_date).last.return_fill_date
  end

  def update_pub_78(path)
    File.open(path) do |file|
      file.readlines.each do |line|
        next unless line.present?

        items     = line.split('|')
        state     = items[3].present? ? items[3] : nil
        data_item = { ein: items[0].strip, org_name: items[1], city: items[2], state: state,
                      country: items[4], deductibility_code: items[5].strip }
        md5                         = MD5Hash.new(columns: data_item.keys)
        data_item[:md5_hash]        = md5.generate(data_item)
        data_item[:run_id]          = run_id
        data_item[:touched_run_id]  = run_id
        data_item[:data_source_url] = 'https://apps.irs.gov/pub/epostcard/data-download-pub78.zip'

        save_row(IrsNonProfitFormsPub78, data_item)
      end
    end
    #delete_not_touch(IrsNonProfitFormsPub78)
  end

  def update_990_n(path)
    keys = IrsNonProfitForms990n.new.attributes.map { |key, _| key.to_sym }[1..26]
    File.open(path) do |file|
      file.readlines.each do |line|
        next unless line.present?

        items     = line.split('|')
        data_item = {}
        keys.each_with_index do |item, index|
          data_item[item] =
            if index == 4
              items[index] == 'T' ? 1 : 0
            elsif [5, 6].include?(index)
              correct_date(items[index])
            else
              items[index]
            end
        end
        data_item            = data_item.each { |key, val| data_item[key] = nil unless val.present? }
        md5                  = MD5Hash.new(columns: data_item.keys)
        data_item[:md5_hash] = md5.generate(data_item)
        data_item[:run_id]   = run_id
        data_item[:touched_run_id]  = run_id
        data_item[:data_source_url] = 'https://apps.irs.gov/pub/epostcard/data-download-epostcard.zip'

        save_row(IrsNonProfitForms990n, data_item)
      end
    end
    #delete_not_touch(IrsNonProfitForms990n)
  end

  def update_auto_rev_list(path)
    keys = IrsNonProfitAutoRevList.new.attributes.map { |key, _| key.to_sym }[1..12]
    File.open(path) do |file|
      file.readlines.each do |line|
        next unless line.present?

        items     = line.split('|')
        data_item = {}
        keys.each_with_index do |item, index|
          data_item[item] =
            if [9, 10, 11].include?(index)
              Date.parse(items[index]) if items[index].present?
            else
              items[index]
            end
        end

        data_item            = data_item.each { |key, val| data_item[key] = nil unless val.present? }
        md5                  = MD5Hash.new(columns: data_item.keys)
        data_item[:md5_hash] = md5.generate(data_item)
        data_item[:run_id]   = run_id
        data_item[:touched_run_id]  = run_id
        data_item[:data_source_url] = 'https://apps.irs.gov/pub/epostcard/data-download-revocation.zip'

        save_several_ein(IrsNonProfitAutoRevList, data_item)
      end
    end
  end

  def update_form_990s(csv, link)
    keys  = IrsNonProfitForms990s.new.attributes.map { |key, _| key.to_sym }[1..9]
    lines = csv.split("\r\n")
    lines.each do |line|
      items     = line.split(',')
      data_item = {}
      keys.each_with_index do |item, index|
        data_item[item] =
          if !items[index].present?
            nil
          elsif index == 4
            raw_date = items[index].split('/')
            year     = raw_date.pop
            raw_date.unshift(year).join('-').to_date
          else
            items[index]
          end
      end
      md5                         = MD5Hash.new(columns: data_item.keys)
      data_item[:md5_hash]        = md5.generate(data_item)
      data_item[:run_id]          = run_id
      data_item[:data_source_url] = link
      data_item[:touched_run_id]  = run_id

      save_several_ein(IrsNonProfitForms990s, data_item)
    end
  end

  def save_org(orgs)
    orgs.each do |org|
      org[:run_id]          = run_id
      org[:touched_run_id]  = run_id
      org[:data_source_url] = 'https://apps.irs.gov/app/eos/'

      save_row(IrsNonProfitOrg, org)
    end
    #delete_not_touch IrsNonProfitOrg
  end

  private

  def save_row(model, row)
    Hamster.logger.debug "#{model} | #{row[:ein]}".green
    forms_db = model.find_by(deleted: 0, ein: row[:ein])

    if forms_db.nil?
      model.store(row)
    elsif forms_db.md5_hash == row[:md5_hash]
      forms_db.update(touched_run_id: run_id)
    elsif forms_db.md5_hash != row[:md5_hash]
      forms_db.update(deleted: 1)
      model.store(row)
    end
    @count += 1
  end

  def save_several_ein(model, row)
    Hamster.logger.debug "#{model} | #{row[:ein]}".green
    forms_db = model.where(deleted: 0, ein: row[:ein])
    @count += 1
    return update_row(model, row) if forms_db.empty?

    key        = model == IrsNonProfitAutoRevList ? :revocation_date  : :return_fill_date
    last_forms = forms_db.max_by { |i| i.send(key).to_date }
    return last_forms.update(touched_run_id: run_id) if last_forms.md5_hash == row[:md5_hash]

    if last_forms.send(key).to_date < row[key]
      forms_db.update(deleted: 1)
      update_row(model, row)
    end
  end

  def update_row(model, row)
    old = model.find_by(md5_hash: row[:md5_hash])
    return model.store(row) unless old

    Hamster.logger.debug "#{model} | #{row[:md5_hash]} | updated deleted row #{old[:id]}".red
    old.update(deleted: 0, touched_run_id: run_id)
  end

  def delete_not_touch(models)
    [models].flatten.each do |model|
      model.where(deleted: 0, touched_run_id: nil)
           .or(model.where(deleted: 0).where.not(touched_run_id: run_id)).update_all(deleted: 1)
    end
  end

  def run
    RunId.new(IrsNonProfitRuns)
  end

  def correct_date(date)
    year_raw = date.match(/-\d{4}$/).to_s
    date.sub!(year_raw, '')
    (year_raw.sub('-', '') + '-' + date).to_date
  end
end
