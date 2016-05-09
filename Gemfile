source 'https://rubygems.org'

gem 'resque', :require => 'resque/server'
gem 'active-fedora', '~> 7.1.0'
gem 'om', '~> 3.1.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'faraday'
#gem 'faraday_middleware'
#gem 'faraday-cookie_jar'
gem 'jstree-rails-4'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'bootstrap-sass', '3.2.0.0'

gem 'config'
gem 'nokogiri-pretty'
gem 'dotenv-rails'

gem 'devise'
gem 'devise_ldap_authenticatable'

gem "activemessaging", :git => "https://github.com/digital-york/activemessaging.git"
gem 'stomp'

gem 'dragonfly'
gem 'remotipart', '~> 1.2'
gem 'jquery-fileupload-rails', github: 'Springest/jquery-fileupload-rails'

# JA added because of 500 error on startup, see https://github.com/tsechingho/chosen-rails/issues/70#issuecomment-92308413
gem "compass-rails", github: "Compass/compass-rails", branch: "master"
#gem 'compass-rails'
gem 'compass'

# errors with 0.4x versions 10/11/2015
gem 'mysql2', '~> 0.3.13'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :production do
  gem 'rack-cache', :require => 'rack/cache'
  #gem 'mysql2'
end


gem 'daemons'
