gem 'haml-rails'
gem 'jquery-rails'
gem 'modernizer-rails'

gem "capistrano", :group => :development

gem 'sqlite3', :group => [ :development, :test ]
gem 'pry', :group => [ :development, :test ]
gem 'rspec-rails', :group => [ :development, :test ]

gem 'mocha', :group => :test
gem 'capybara', :group => :test
gem 'factory_girl_rails', :group => :test
gem 'spork', '> 0.9.0.rc', :group => :test
gem 'gurad-livereload', :group => :test
gem 'guard-rspec', :group => :test
gem 'guard-spork', :group => :test

gem 'therubyracer',:group => :assets
gem 'compass', '~> 0.12.alpha', :group => :assets

run 'bundle install'

rake "rspec:install"
run "bundle exec spork --bootstrap"

run "bundle exec guard init"
run "bundle exec guard init rspec"
run "bundle exec guard init livereload"
run "bundle exec guard init spork"

run "echo '--colour --format d --drb' >> .rspec"

remove_file 'app/views/layouts/application.html.erb'
create_file 'app/views/layouts/application.html.haml' do
  <<-eof
<!doctype html>
<!-- paulirish.com/2008/conditional-stylesheets-vs-css-hacks-answer-neither/ -->
<!--[if lt IE 7]> <html class="no-js ie6 oldie" lang="en"> <![endif]-->
<!--[if IE 7]>    <html class="no-js ie7 oldie" lang="en"> <![endif]-->
<!--[if IE 8]>    <html class="no-js ie8 oldie" lang="en"> <![endif]-->
<!-- Consider adding a manifest.appcache: h5bp.com/d/Offline -->
<!--[if gt IE 8]><!--> <html class="no-js" lang="en"> <!--<![endif]-->
%head
  %meta{:charset => "utf-8"}
  /
    Use the .htaccess and remove these lines to avoid edge case issues.
    More info: h5bp.com/b/378
  %meta{:content => "IE=edge,chrome=1", "http-equiv" => "X-UA-Compatible"}
  %title
  %meta{:content => "", :name => "description"}
  %meta{:content => "", :name => "author"}
  / Mobile viewport optimized: j.mp/bplateviewport
  %meta{:content => "width=device-width,initial-scale=1", :name => "viewport"}

  = stylesheet_link_tag "application"
  = yield :stylesheet
  = javascript_include_tag "modernizr"
  = csrf_meta_tags
%body
  .container
    #nav
      %nav
        %li
          site
    -if notice
      %p#notice= notice
    %div{:role => "main", :id => "main"}
      = yield
    %footer#footer
  = javascript_include_tag "application"
  = yield :javascript

<!-- Prompt IE 6 users to install Chrome Frame. Remove this if you want to support IE 6. chromium.org/developers/how-tos/chrome-frame-getting-started -->
<!--[if lt IE 7 ]>
<script defer src="//ajax.googleapis.com/ajax/libs/chrome-frame/1.0.3/CFInstall.min.js"></script>
<script defer>window.attachEvent('onload',function(){CFInstall.check({mode:'overlay'})})</script>
<![endif]-->
  eof
end


# clean up rails defaults
remove_file 'rm public/images/rails.png'
remove_file 'public/index.html'
run 'cp config/database.yml config/database.example'
run "echo 'config/database.yml' >> .gitignore"
run "echo '.sass-cache/' >> .gitignore"

capify!
run 'cp config/deploy.rb config/deploy.example'
run "echo 'config/deploy.rb' >> .gitignore"

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


git :init
git :add => "."
git :commit => "-a -m 'create initial application'"
