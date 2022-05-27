# Implementation process
shortener API on ruby on rails, as part of the fullstack challenge.
Built it without previous experience on ruby on rails, that made me do a lot of research about how things work on the framework.
## Adding the short_code field

    On the migration file I added a column short_code to be able to store the value of the shortened url

## Adding nokogiri gem

    On the Gemfile I added the nokogiri gem to extract the title of the website

## short_urls_controller.rb
- index method
    Here I obtained all the records ordered by their click count limiting the sql query to 100
    ```sh
    urls = ShortUrl.order('click_count DESC').limit(100);
    render json: {urls:urls}, status:200
    ```
- create method
    I instanciate a new ShortUrl object passing the full url as an argument, once the object was saved on the database, I called the short_code method to generate the shortcode url and assigned it to the short_code variable to return it on the response, then assigned the generated shortcode to the short_code attribute of the object and save it. If the object was not save I returned the error of the invalid url. More details of how the shortcode is generated on the short_url.rb model section.
    ```sh
    shortUrl = ShortUrl.new(full_url: shortUrl_params)
    if shortUrl.save 
      short_code = shortUrl.short_code
      shortUrl.short_code = short_code
      shortUrl.save!
      render json: {"short_code": short_code}, status:200
    else
      render json: shortUrl.errors, status:400
    end
    ```
- show method
    I try to retrive a record using the short_code as a parameter if the record was not present on the database return a 404 error, otherwise I update the record value of click_count adding 1 to then make the redirect to the stored full url.
    ```sh
    shortUrl = ShortUrl.find_by_short_code(params[:id])
    if shortUrl.nil?
      render json: {"error": "url not found"}, status:404
    else
      shortUrl.update_attribute(:click_count, shortUrl.click_count + 1 )
      redirect_to shortUrl.full_url
    end
    ```
- shortUrl_params
    This method is to tell the controller which parameters are required and be able to create a new object of the ShortUrl class
    ```sh
    def shortUrl_params
        params.require(:full_url)
    end
    ```
## short_url.rb
##### Logic of the model ShortUrl
- Added a Regular expression to validate the url
    ```sh
    REGEX = /^(((http|https):\/\/|)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}(:[0-9]{1,5})?(\/.*)?)$/
    ```
- Added a callback to update the title after a record was created
    ```sh
    after_create :update_title!
    ```
- short_code method
    This is a "base 62" encoder for the id generated for the record on the database that way we assure the minimum lenght possible of the shortcode in dependency of the total of records on the system, what this does is to take the id of the object assign to the number variable, return the character "0" when number equals to zero, if the number is greater than zero it will concatenate to the short_url variable the character on the postion of the CHARACTERS array, in order to determinate which position use, we use the result of the number modulo 62, then we divide the number by 62 to be able to continue on the while loop or return the shortcode. modulo 62 and the division by 62 is beacuse that is the lenght of the CHARACTERS array.
     ```sh
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
    ```
- update_title! method
    Here I called the method perform_later of the UpdateTitleJob class to be enqueue passing the id of the record.
    ```sh
    UpdateTitleJob.perform_later(self.id)
    ```
- validate_full_url method
    On this method I assigned the value of the full url to the variable is_valid, then compare it with the regex expressio, in case the url was invalid I added the error, this error is displayed on the controller create method too.
    ```sh
    is_valid = self.full_url;
    if !is_valid.match?(REGEX)
       errors.add(:errors,"Full url is not a valid url")
    end
    ```
## update_title_job.rb
- Added the require 'open-uri' to use it to fetch the url

- perform method
    
    Get the record from the database using the id, then using Nokogiri parse the html of the full url and extract the value of the title tag, then assign the title value to the object and save it to update the record on the database.
    ```sh
    shortUrl = ShortUrl.find(short_url_id)
    title = Nokogiri::HTML.parse(open(shortUrl.full_url)).title
    shortUrl.title = title
    shortUrl.save
    ```

# Intial Setup

    docker-compose build
    docker-compose up mariadb
    # Once mariadb says it's ready for connections, you can use ctrl + c to stop it
    docker-compose run short-app rails db:migrate
    docker-compose -f docker-compose-test.yml build

# To run migrations

    docker-compose run short-app rails db:migrate
    docker-compose -f docker-compose-test.yml run short-app-rspec rails db:test:prepare

# To run the specs

    docker-compose -f docker-compose-test.yml run short-app-rspec

# Run the web server

    docker-compose up

# Adding a URL

    curl -X POST -d "full_url=https://google.com" http://localhost:3000/short_urls.json

# Getting the top 100

    curl localhost:3000

# Checking your short URL redirect

    curl -I localhost:3000/abc
