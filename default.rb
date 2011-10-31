require "net/http"
require "net/https"

def download(source, destination)
  uri = URI.parse(source)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if source =~ /^https/
  request = Net::HTTP::Get.new(uri.path)
  contents = http.request(request).body
  path = File.join(destination_root, destination)
  File.open(path, "w") { |file| file.write(contents) }
end

git :init
git :add => "."
git :commit => "-aqm 'create initial application'"

#gems
append_file 'Gemfile' do
  <<-eof
  gem 'haml-rails'
  gem 'modernizr-rails'

  group :development do
    gem "capistrano"
  end

  group :development, :test do
    gem 'sqlite3'
    gem 'pry'
    gem 'rspec-rails'
  end

  group :test do
    gem 'mocha'
    gem 'capybara'
    gem 'factory_girl_rails'
    gem 'spork', '> 0.9.0.rc'
    gem 'guard-livereload'
    gem 'guard-rspec'
    gem 'guard-spork'
  end
  eof
end

inject_into_file 'Gemfile', :after => 'group :assets do' do
  <<-eof
    gem 'therubyracer'
    gem 'compass', "~> 0.12.alpha", :require => false
    gem 'compass-susy-plugin', :require => 'susy'
  eof
end

run 'bundle install'

git :add => "."
git :commit => "-aqm 'custom gems'"

source_paths << "."

say 'replace layout'
remove_file 'app/views/layouts/application.html.erb'
download 'https://raw.github.com/sch1zo/rails-template/master/files/application.html.haml', "app/views/layouts/application.html.haml"

say 'assets'
say 'normalizer stylesheet'
download "https://raw.github.com/jonathantneal/normalize.css/master/normalize.css", "normalize.css"
run "bundle exec sass-convert -F css -T sass normalize.css vendor/assets/stylesheets/normalize.css.sass"
remove_file "normalize.css"
prepend_to_file "vendor/assets/stylesheets/normalize.css.sass", "//=require_self\n\n"

say 'susy setup'
download "https://raw.github.com/sch1zo/rails-template/master/files/base.css.sass", "app/assets/stylesheets/base.css.sass"
download "https://raw.github.com/sch1zo/rails-template/master/files/defaults.css.sass", "app/assets/stylesheets/defaults.css.sass"
download "https://raw.github.com/sch1zo/rails-template/master/files/common.css.sass", "app/assets/stylesheets/common.css.sass"
remove_file "app/assets/stylesheets/application.css"
download "https://raw.github.com/sch1zo/rails-template/master/files/application.css.sass", "app/assets/stylesheets/application.css.sass"

git :add => "."
git :commit => "-aqm 'layout and assets'"

say 'clean up rails defaults'
remove_file 'app/assets/images/rails.png'
remove_file 'public/index.html'
copy_file 'config/database.yml', 'config/database.example'
append_to_file '.gitignore', 'config/database.yml'

git :add => "."
git :commit => "-aqm 'cleanup defaults'"

say 'capistrano'
capify!
download "https://raw.github.com/sch1zo/rails-template/master/files/deploy.rb.erb", "tmp/deploy.rb.erb"
template "tmp/deploy.rb.erb", 'config/deploy.rb'
remove_file "tmp/deploy.rb.erb"
copy_file 'config/deploy.rb', 'config/deploy.example'
append_to_file '.gitignore', 'config/deploy.rb'

git :add => "."
git :commit => "-aqm 'capistrano'"

say 'setup rspec/guard/spork'
download "https://raw.github.com/sch1zo/rails-template/master/files/Guardfile", 'Guardfile'

create_file '.rspec', '--color --format d --drb'
empty_directory 'spec/support'
download "https://raw.github.com/sch1zo/rails-template/master/files/spec_helper.rb", "spec/spec_helper.rb"

create_file 'spec/factories.rb', "FactoryGirl.define do\n\nend"

git :add => "."
git :commit => "-aqm 'rspec/guard/spork'"

say 'setup default generators'
inject_into_file 'config/application.rb', :after => "config.filter_parameters += [:password]" do
  <<-eos
    # Do not generate test files
    config.generators do |g| 
      g.test_framework :rspec, :views => false
      g.integration_tool false
    end
  eos
end

git :add => "."
git :commit => "-aqm 'default generators'"


remove_file "README"
download "https://raw.github.com/sch1zo/rails-template/master/files/readme.md.erb", "readme.md.erb"
template "readme.md.erb", "readme.md"
remove_file "readme.md.erb"

git :add => "."
git :commit => "-aqm 'readme'"


initializer("app_config.rb") do
  <<-eof
  #load yml file
  unless File.exists? Rails.root.join('config','app_config.yml')
    require 'fileutils'
    FileUtils.cp Rails.root.join('config','app_config.example'), Rails.root.join('config','app_config.yml')
    puts "[INFO] app_config.yml created"
  end

  require 'ostruct'
  APP_CONFIG = OpenStruct.new(YAML.load_file(Rails.root.join('config','app_config.yml') )[::Rails.env] )
  eof
end
download "https://raw.github.com/sch1zo/rails-template/master/files/app_config.example", "config/app_config.example"

git :add => "."
git :commit => "-aqm 'app_config initializer and example file'"

create_file ".travis.yml" do
  <<-eof
  rvm:
    - ree
    - 1.9.2
    - 1.9.3
  before_script:
    - "mv config/database.example config/database.yml"
    - "bundle exec rake db:migrate"
  notifications:
    email:
      - dev@eger.lc
  eof
end
append_to_file "Rakefile", "\n\nRake::Task[:default].prerequisites.clear\ntask :default => :spec"

git :add => "."
git :commit => "-aqm 'initial travis setup'"

rake "db:create"
