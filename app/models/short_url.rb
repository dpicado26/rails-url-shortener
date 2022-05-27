class ShortUrl < ApplicationRecord
  REGEX = /^(((http|https):\/\/|)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}(:[0-9]{1,5})?(\/.*)?)$/
  CHARACTERS = [*'0'..'9', *'a'..'z', *'A'..'Z'].freeze
  validate :validate_full_url
  after_create :update_title!

 def short_code
    number = self.id
    if number == 0
        return "0" 
    end
    short_url = ""
    while number > 0
      short_url = CHARACTERS[number % 62] + short_url
      number = number / 62
    end
     short_url
  end


  def update_title!
    UpdateTitleJob.perform_later(self.id)
  end

  private

  def validate_full_url
    is_valid = self.full_url;
    if !is_valid.match?(REGEX)
       errors.add(:errors,"Full url is not a valid url")
    end
  end

end
