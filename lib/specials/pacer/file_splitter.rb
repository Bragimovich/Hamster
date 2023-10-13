module FileSplitter
  SPLITTER_STRING = '###BODY###'

  def create_content(body, url, status, case_id)
    "#{url}#{SPLITTER_STRING}#{status}#{SPLITTER_STRING}#{case_id}#{SPLITTER_STRING}#{body}"
  end

  def split_link(file_content)
    file_content.split(SPLITTER_STRING).first
  end

  def split_html(file_content)
    file_content.split(SPLITTER_STRING).last
  end

  def split_status(file_content)
    file_content.split(SPLITTER_STRING)[1]
  end

  def split_case_id(file_content)
    file_content.split(SPLITTER_STRING)[2]
  end
end