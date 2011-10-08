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

#replace layout
remove_file 'app/views/layouts/application.html.erb'
get "https://raw.github.com/sch1zo/rails-template/master/files/application.html.haml", "app/views/layouts/application.html.haml"

#assets
#normalizer stylesheet
get "https://raw.github.com/jonathantneal/normalize.css/master/normalize.css" "normalize.css"
run "bundle exec sass-convert -F css -T sass normalize.css vendor/assets/stylesheets/normalize.css.sass"
remove_file "normalize.css"

#susy setup
get "https://raw.github.com/sch1zo/rails-template/master/files/base.css.sass", "app/assets/stylesheets/base.css.sass"
get "https://raw.github.com/sch1zo/rails-template/master/files/defaults.css.sass", "app/assets/stylesheets/defaults.css.sass"
get "https://raw.github.com/sch1zo/rails-template/master/files/common.css.sass", "app/assets/stylesheets/common.css.sass"
remove_file "app/assets/stylesheets/application.css"
get "https://raw.github.com/sch1zo/rails-template/master/files/application.css.sass", "app/assets/stylesheets/application.css.sass"


# clean up rails defaults
remove_file 'rm public/images/rails.png'
remove_file 'public/index.html'
copy_file 'config/database.yml', 'config/database.example'
append_to_file '.gitignore', 'config/database.yml'

# capistrano
capify!
get "https://raw.github.com/sch1zo/rails-template/master/files/deploy.rb.erb", "tmp/deploy.rb.erb"
template "tmp/deploy.rb.erb", 'config/deploy.rb'
remove_file "tmp/deploy.rb.erb"
copy_file 'config/deploy.rb', 'config/deploy.rb.example'
append_to_file '.gitignore', 'config/deploy.rb'

#setup rspec/guard/spork
rake "rspec:install"
get "https://raw.github.com/sch1zo/rails-template/master/files/Guardfile", 'Guardfile'
run "bundle exec spork --bootstrap"

create_file '.rspec', '--colour --format d --drb'
inject_into_file 'spec/spec_helper.rb', :after => "RSpec.configure do |config|" do
  <<-eof
    config.mock_with :mocha
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
  eof
end
inject_into_file 'spec/spec_helper.rb', "\nrequire 'capybara/rspec'", :after => "require 'rspec/rails'"
inject_into_file 'spec/spec_helper.rb', "\nFactoryGirl.reload", :after => "# This code will be run each time you run your specs."

inject_into_file 'config/application.rb', :after => "config.filter_parameters += [:password]" do
  <<-eos
    # Do not generate test files
    config.generators do |g| 
      g.test_framework :rspec, :fixture = true, :views => false
      g.integration_tool false
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
    end
  eos
end

#git
git :init
git :add => "."
git :commit => "-a -m 'create initial application'"
