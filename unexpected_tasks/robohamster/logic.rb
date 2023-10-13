rh_config = {}
tables_keywords = %i[
  db_location
]
db_config = {
  host: rh_config[:tables][:db_location][:server],
  db: rh_config[:tables][:db_location][:schema]
}
table_names = rh_config[:tables].key.delete_if { |el| tables_keywords.include? el }
table_name = Symbol
endpoint_url = String
search_query = "##{css_id} #{tag} .#{css_class}"
endpoint_root = Nokogiri::HTML(endpoint_url).css(search_query)

{
  index_page: nil,
  tables: {
    db_config: db_config,
    tables_config: {

    }
  }
}
