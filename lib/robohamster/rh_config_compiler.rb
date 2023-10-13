# frozen_string_literal: true

class RoboHamsterConfigCompiler < Hamster::Harvester

    attr_reader :index, :page, :database, :next_page, :column_in_table, :column_types

    def initialize(config)
      super
      @config = config
      db_location
      page_columns
    end

    def to_hash
      @config
    end

    def navigation
      if 'navigation'.in? @config["index_page"]
        @next_page = str_for_nokogiri(@config["index_page"]["navigation"])
      end
      @next_page
    end

    def url
      @config["url"]
    end

    def db_location
      @database = @config["tables"]["db_location"]
      @config["tables"].delete("db_location")
    end

    def tables
      @config["tables"].keys
    end

    def page_columns
      @index = {
        root: str_for_nokogiri(@config["index_page"]["root"]),
        element: str_for_nokogiri(@config["index_page"]["item"]),
        columns: {}
      }

      @page = {}
      @column_in_table = {}
      @column_types = {}

      @config["tables"].each do |table_name, columns|
        page_columns = {}
        @column_types[table_name] = {}
        @column_in_table[table_name] = []


        columns["columns"].each do |column_name, additional|
          column_parameters = {
            table: table_name,
            nokogiri: str_for_nokogiri(additional)
          }
          column_parameters = column_parameters.merge(add_additional_parameters(additional))

          if "from_index".in?(additional)
            @index[:columns][column_name] = column_parameters
          else
            page_columns[column_name] = column_parameters
          end

          @column_in_table[table_name].push(column_name)
          @column_types[table_name][column_name] = additional["data_type"]
        end
        @page[table_name] = {
          root: str_for_nokogiri(@config["tables"][table_name]["root"]),
          columns: page_columns
        }
      end
    end

    private


    def element_definition
      {
        tag: nil,
        css_id: nil,
        css_class: nil,
        gather: 'inner content',
      }
    end

    # Make string for put in Nokogiri from config. Order: id -> tag -> class -> attribute=attribute_val.
    # example:
    #   element_config = {tag: 'table', css_class: 'searchResults'}
    #   str_for_nokogiri(element_config)
    #   >> "table.searchResults"
    def str_for_nokogiri(element_config)
      element_nokogiri = ""
      element_nokogiri += "#" + element_config["css_id"].split(/[ ,]/).join(' #') unless element_config["css_id"].nil?
      element_nokogiri += " #{element_config["tag"]}"
      element_nokogiri += "." + element_config["css_class"].split(/[ ,]/).join(' .') unless element_config["css_class"].nil?
      element_nokogiri += "[@#{element_config["attribute"]}='#{element_config["attribute_value"]}']" unless element_config["attribute"].nil?
      element_nokogiri
    end

    def additional_parameters
      [:cut_from, :cut_to, :gather, :data_type, :attribute, :attribute_value, :date_structure]
    end

    def add_additional_parameters(additional)
      parameters = {}
      additional_parameters.each do |param|
        if additional[param]
          parameters[param] = additional[param]
        elsif additional[param.to_s]
          parameters[param] = additional[param.to_s]
        end
      end
      parameters
    end

end