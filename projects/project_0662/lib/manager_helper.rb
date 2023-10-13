module ManagerHelper
  def suspension_data(link_appender, option1, option2)
    links = download_inner_xls(link_appender, option1, option2)
    links[0..-2].each do |link|
      xls_links = parser.get_suspension_link(get_main_page(link))
      get_xls(xls_links, "suspension")
    end
  end

  def salary_student_data(link_appender, option1, option2)
    links = download_inner_xls(link_appender, option1, option2)
    links.each do |link|
      salary_links, student_links = parser.get_staff_link(get_main_page(link))
      get_xls(salary_links, "salary")
      get_xls(student_links, "student")
    end
  end

  def graduation_data(option)
    links = parser.get_graduation_links(get_main_page(option))
    links.each do |link|
      download_xls(link, "district and school graduates and completers by subgroups", "graduation")
    end
  end

  def cmas_data(link_appender, option1, option2)
    main_page = get_main_page(link_appender)
    links = parser.get_inner_page_links(main_page, option1, option2)
    links[0...-2].each do |link|
      download_xls(link, "district and school overall results", "cmas")
    end
  end

  def attendance_data(option1, option2)
    links = parser.get_links(get_main_page(option1), option2)
    get_xls(links[0..6], "attendance")
  end

  def dropout_data(link_appender, option1)
    main_page = get_main_page(link_appender)
    links =  parser.get_links(main_page, option1)
    links[0..6].each do |link|
      download_xls(link, "workbook containing both district and school level data", "dropout")
    end
  end

  def psat_data(link_appender, option1, option2)
    download_xls(link_appender, option1, option2)
  end
end
