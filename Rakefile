require "bundler/gem_tasks"
require "rake/clean"

directory "dev_site"

file "dev_site/Gemfile" => "dev_site" do
  sh "echo 'source \"https://rubygems.org\"\n\n"\
     "group :jekyll_plugins do\n"\
     "  gem \"jekyll-rp_logs\"\n"\
     "end' > dev_site/Gemfile\n"
end

file "dev_site/Rakefile" => "dev_site" do
  sh "echo 'require \"jekyll/rp_logs\"' >> dev_site/Rakefile"
end

CLEAN.include("dev_site/*")

desc 'Deploys the site to the dev_site directory and serves it for testing'
task :deploy => ["clean", "install", "dev_site", "dev_site/Gemfile", "dev_site/Rakefile"] do 
  puts Dir.pwd
  Bundler.with_clean_env do 
    Dir.chdir("dev_site") do
      puts Dir.pwd
      sh "bundle"
      sh "bundle exec rake rp_logs:new"
      # Copy test data in!
      cp_r "../test/_rps", "."
      sh "bundle exec jekyll serve --config _config.yml"
    end
  end
end

