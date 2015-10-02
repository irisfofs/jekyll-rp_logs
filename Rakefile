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

desc "Create and populate the dev_site directory, ready for building or serving"
task deploy: ["clean", "dev_site", "dev_site/Gemfile", "dev_site/Rakefile"] do
  Bundler.with_clean_env do
    Dir.chdir("dev_site") do
      sh "bundle --quiet"
      sh "bundle exec rake rp_logs:new"
      # Copy test data in!
      cp_r "../test/_rps", "."
    end
  end
end

desc "Deploys the site to the dev_site directory and serves it for testing"
task serve: ["deploy", "install"] do
  Bundler.with_clean_env do
    Dir.chdir("dev_site") do
      sh "bundle exec jekyll serve --trace --config _config.yml"
    end
  end
end
