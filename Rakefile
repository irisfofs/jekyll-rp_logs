require "bundler/gem_tasks"
require "jekyll/rp_logs"
require "rake/clean"

DEV_SITE_DIR = "dev_site"

CLEAN.include(DEV_SITE_DIR)

desc "Create and populate the dev_site directory, ready for building or serving"
task deploy: %w(clean install) do
  Bundler.with_clean_env do
    Rake::Task["rp_logs:create_new_site"].invoke(DEV_SITE_DIR)
    Dir.chdir(DEV_SITE_DIR) do
      # Copy test data in!
      cp_r "../test/_rps", "."
    end
  end
end

desc "Deploys the site to the dev_site directory and serves it for testing"
task serve: :deploy do
  Bundler.with_clean_env do
    Dir.chdir(DEV_SITE_DIR) do
      sh "bundle exec jekyll serve --trace --config _config.yml"
    end
  end
end
