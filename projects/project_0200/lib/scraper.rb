class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end
  
  def get_request(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def post_to_graphql(url, limit, offset)
    form_data = {
      operationName:	"GetPostCards",
      variables: {limit: limit, offset: offset},
      query: "query GetPostCards($limit: Int, $offset: Int, $categorySlug: String, $caucusSlug: String, $memberSlug: String, $title: String) {  posts(    filters: {and: [{title: {contains: $title}}, {categories: {slug: {eq: $categorySlug}}}, {caucus: {slug: {eq: $caucusSlug}}}, {members: {slug: {eq: $memberSlug}}}]}    pagination: {limit: $limit, start: $offset}    sort: \"published:desc\"  ) {    data {      id      attributes {        published        title        slug        content        featuredImg {          ...Media          __typename        }        categories {          data {            ...Category            __typename          }          __typename        }        __typename      }      __typename    }    meta {      pagination {        total        __typename      }      __typename    }    __typename  }}fragment Media on UploadFileEntityResponse {  data {    attributes {      name      caption      url      formats      alternativeText      height      width      __typename    }    __typename  }  __typename}fragment Category on CategoryEntity {  id  attributes {    title    slug    icon {      variant      __typename    }    fallbackImg {      ...Media      __typename    }    __typename  }  __typename}"
    }.to_json

    headers = { 'Content-Type': 'application/json' }

    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter, method: :post ,req_body: form_data, ssl_verify: false, headers: headers)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  private

  def reporting_request(response)
    if response.present?
      puts '=================================='.yellow
      print 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      puts response.status == 200 ? status.greenish : status.red
      puts '=================================='.yellow
    end
  end
end