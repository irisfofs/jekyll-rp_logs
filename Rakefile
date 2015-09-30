require "bundler/gem_tasks"
require "rake/clean"

directory "dev_site"

file "dev_site/Gemfile" => "dev_site" do |tsk|
  File.open(tsk.name, "w") do |f|
    f << <<-END.gsub(/^\s+\|/, "")
      |source "https://rubygems.org"
      |
      |group :jekyll_plugins do
      |  gem "jekyll-rp_logs"
      |end
    END
  end
end

file "dev_site/Rakefile" => "dev_site" do |tsk|
  File.open(tsk.name, "w") do |f|
    f << 'require "jekyll/rp_logs"'
  end
end

CLEAN.include("dev_site/*")

desc "Deploys the site to the dev_site directory and serves it for testing"
task deploy: ["clean", "install", "dev_site", "dev_site/Gemfile", "dev_site/Rakefile"] do
  puts Dir.pwd
  Bundler.with_clean_env do
    Dir.chdir("dev_site") do
      puts Dir.pwd
      sh "bundle"
      sh "bundle exec rake rp_logs:new"
      # Copy test data in!
      cp_r "../test/_rps", "."
      sh "bundle exec jekyll serve --trace --config _config.yml"
    end
  end
end
