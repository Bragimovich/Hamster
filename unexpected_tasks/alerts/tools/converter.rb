  def convert(size)
    case
    when size < 1024
      "#{size} KB"
    when size < 1048576
      "#{(size / 1024.0).round(2)} MB"
    else
      "#{(size / 1048576.0).round(2)} GB"
    end
  end
