class UpdateTitleJob < ApplicationJob
   require 'open-uri'
  queue_as :default

  def perform(short_url_id)
    shortUrl = ShortUrl.find(short_url_id)
    title = Nokogiri::HTML.parse(open(shortUrl.full_url)).title
    shortUrl.title = title
    shortUrl.save
  end
end
