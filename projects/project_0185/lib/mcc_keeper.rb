require_relative '../models/mcc'

class MccKeeper

  def links
    MCC.pluck(:link)
  end

  def save_news(news)
     news.nil? ? nil : MCC.store(news)
  end
end
