require_relative '../keeper'

def parser_genaral_info(arr_names_files)

  @domain = 'https://www.in.gov/doe/files/'

  @keeper = Keeper.new
  @md5_cash_maker = {
    :in_general_info => MD5Hash.new(columns:%i[is_district district_id number name nces_id type low_grage high_grade phone fax website address city county state zip]),
    :in_administrators => MD5Hash.new(columns:%i[general_id role first_name last_name email])
  }

  arr_names_files.each do |file_name|

    logger.info "*************** Starting parser of #{file_name} ***************"

    path = "#{storehouse}store/general/#{file_name}"

    xlsx = Roo::Spreadsheet.open(path)

    @sheets = xlsx.sheets

    (0..@sheets.length - 1).each do |i|

      hash_in_general_info = {
        # is_district: sheet == 'CORP' ? 1 : 0,
        # district_id: 0,
        number: @sheets[i] == 'CORP' ? 'IDOE_CORPORATION_ID' : 'IDOE_SCHOOL_ID',
        name: @sheets[i] == 'CORP' ? 'CORPORATION_NAME' : 'SCHOOL_NAME',
        # nces_id: 'NCES_ID',
        # type: if sheet == 'CORP'
        #         'CORPORATION_TYPE'
        #       else
        #         sheet == 'SCHL' ? 'public school' : 'private school'
        #       end,
        low_grage: 'LOW_GRADE',
        high_grade: 'HIGH_GRADE',
        # locale: 'LOCALE',
        phone: 'PHONE',
        fax: 'FAX',
        website: @sheets[i] == 'CORP' ? 'CORPORATION_HOMEPAGE' : 'SCHOOL_HOMEPAGE',
        address: 'ADDRESS',
        city: 'CITY',
        county: 'COUNTY_NAME',
        state: 'STATE',
        zip: 'ZIP'
      }
      hash_in_administrators = {
        # general_id: 1,
        # role: 'Superintendent',
        # full_name: '',
        # first_name: sheet == 'CORP' ? 'SUPERINTENDENT_FIRST_NAME' : 'PRINCIPAL_FIRST_NAME',
        # last_name: sheet == 'CORP' ? 'SUPERINTENDENT_LAST_NAME' : 'PRINCIPAL_LAST_NAME',
        # email: sheet == 'CORP' ? 'SUPERINTENDENT_EMAIL' : 'PRINCIPAL_EMAIL',
      }

      logger.info "*************** Starting parser of #{@sheets[i]} ***************"

      if @sheets[i] == 'CORP' or @sheets[i] == 'SCHL'
        hash_in_general_info[:nces_id] = 'NCES_ID'
        if @sheets[i] == 'CORP' then hash_in_general_info[:type] = 'CORPORATION_TYPE' end
        if @sheets[i] == 'SCHL' then hash_in_general_info[:locale] = 'LOCALE' end
      end

      if @sheets[i] == 'CORP'
        hash_in_administrators[:first_name] = 'SUPERINTENDENT_FIRST_NAME'
        hash_in_administrators[:last_name] = 'SUPERINTENDENT_LAST_NAME'
        hash_in_administrators[:email] = 'SUPERINTENDENT_EMAIL'
      else
        hash_in_administrators[:first_name] = 'PRINCIPAL_FIRST_NAME'
        hash_in_administrators[:last_name] = 'PRINCIPAL_LAST_NAME'
        hash_in_administrators[:email] = 'PRINCIPAL_EMAIL'
      end

      if @sheets[i] == 'SCHL' then hash_in_general_info[:helper] = 'IDOE_CORPORATION_ID' end

      # Create hash for in_general_info table
      xlsx.sheet(@sheets[i]).each(hash_in_general_info) do |hash|

        hash[:is_district] = @sheets[i] == 'CORP' ? 1 : 0
        hash[:district_id] = @sheets[i] == 'SCHL' ? @keeper.get_district_id(hash[:helper]) : nil
        hash[:data_source_url] = @domain + file_name

        if @sheets[i] != 'CORP'
          hash[:type] = @sheets[i] == 'SCHL' ? 'public school' : 'private school'
        end

        if hash[:low_grage] != "LOW_GRADE"
          hash.delete(:helper)
          if @keeper.existed_data_general_table(hash).nil?
            hash[:md5_hash] = @md5_cash_maker[:in_general_info].generate(hash)
            @keeper.save_on_general_info(hash)
            # puts hash.inspect
          end
        end
      end

      # Create hash for in_administrators table
      hash_in_administrators[:helper] = @sheets[i] == 'CORP' ? 'CORPORATION_NAME' : 'SCHOOL_NAME'

      xlsx.sheet(@sheets[i]).each(hash_in_administrators) do |hash|

        full_name = [hash[:first_name], hash[:last_name]].join(' ')

        hash[:general_id] = @keeper.get_id(hash[:helper])
        hash[:role] = @sheets[i] == 'CORP' ? 'Superintendent' : 'Principal'
        hash[:full_name] = full_name != ' ' ? full_name : nil
        hash[:data_source_url] = @domain + file_name

        if hash[:first_name] != "SUPERINTENDENT_FIRST_NAME" and hash[:first_name] != "PRINCIPAL_FIRST_NAME"
          hash.delete(:helper)
          if @keeper.existed_data_administrators_table(hash).nil?
            hash[:md5_hash] = @md5_cash_maker[:in_administrators].generate(hash)
            @keeper.save_on_administrators(hash)
            # puts hash.inspect
          end
        end
      end
    end
    end
end
