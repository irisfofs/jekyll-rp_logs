Y_OR_N = %w(y n)
NO = "n"

def copy_unless_exist(from, to, message = nil)
  return if File.exist?(to)
  puts message if message
  cp from, to
end

# Octopress
def get_stdin(message)
  print message
  STDIN.gets.chomp
end

# Octopress
def ask(message, valid_options = Y_OR_N)
  if valid_options
    valid_str = valid_options.to_s.delete('"').gsub(/, /, "/")
    answer = get_stdin("#{message} #{valid_str} ") until valid_options.include?(answer)
  else
    answer = get_stdin(message)
  end
  answer
end

namespace :rp_logs do
  desc "Create a new Jekyll site for RP logs, with the default theme"
  task :create_new_site, [:dir] => [:site_dir] do |_task, args|
    Dir.chdir(args[:dir]) do
      Rake::Task["rp_logs:bundler"].invoke
      Rake::Task["rp_logs:copy_theme"].invoke
    end
  end

  task :site_dir, [:dir] do |_task, args|
    if Dir.exist? args[:dir]
      if (Dir.entries(args[:dir]) - %w(. ..)).empty?
        puts "Using empty directory #{args[:dir]}"
      else
        fail "Directory #{args[:dir]} already exists, and is non-empty. Won't overwrite."
      end
    else
      mkdir_p args[:dir]
    end
  end

  directory "_rps"

  file "Gemfile" do |tsk|
    File.open(tsk.name, "w") do |f|
      f << <<-END.gsub(/^\s+\|/, "")
        |source "https://rubygems.org"
        |
        |group :jekyll_plugins do
        |  gem "jekyll-rp_logs", :git => "git://github.com/tecknojock/jekyll-rp_logs"
        |end
      END
    end
  end

  task bundler: "Gemfile" do
    sh "bundle"
  end

  task copy_theme: :_rps do
    gem_root = Gem::Specification.find_by_name("jekyll-rp_logs").gem_dir
    cp_r Dir["#{gem_root}/.themes/default/source/*"], "./"
    copy_unless_exist("_config.yml.default", "_config.yml")
    copy_unless_exist("_tags.yml.default", "_tags.yml")
    touch "_sass/_custom-vars.scss"
    touch "_sass/_custom-rules.scss"
  end

  task :update_theme do
    if !File.exist?("_config.yml")
      resp = ask("No _config.yml found. This may not be a Jekyll site directory. Install theme anyway?")
      abort("Didn't install theme.") if resp == NO
    elsif File.exist?("_sass")
      resp = ask("A theme is already installed. Overwrite existing non-custom files?")
      abort("Kept existing theme.") if resp == NO
    end
    Rake::Task["rp_logs:copy_theme"].invoke
  end
end
