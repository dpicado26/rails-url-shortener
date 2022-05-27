class ShortUrlsController < ApplicationController

  # Since we're working on an API, we don't have authenticity tokens
  skip_before_action :verify_authenticity_token

  def index
    urls = ShortUrl.order('click_count DESC').limit(100);
    render json: {urls:urls}, status:200
  end

  def create
    shortUrl = ShortUrl.new(full_url: shortUrl_params)
    if shortUrl.save 
      short_code = shortUrl.short_code
      shortUrl.short_code = short_code
      shortUrl.save!
      render json: {"short_code": short_code}, status:200
    else
      render json: shortUrl.errors, status:400
    end
  end

  def show
    shortUrl = ShortUrl.find_by_short_code(params[:id])
    if shortUrl.nil?
      render json: {"error": "url not found"}, status:404
    else
      shortUrl.update_attribute(:click_count, shortUrl.click_count + 1 )
      redirect_to shortUrl.full_url
    end
  end

 # private

  def shortUrl_params
    params.require(:full_url)
  end

end
