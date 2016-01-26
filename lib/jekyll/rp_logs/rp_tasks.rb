require "rake"

module Jekyll
  module RpLogs
    class RpTasks
      include Rake::DSL if defined? Rake::DSL

      def copy_unless_exist(from, to, message = nil)
        unless File.exist?(to)
          puts message if message
          cp from, to
        end
      end

      # Octopress
      def get_stdin(message)
        print message
        STDIN.gets.chomp
      end

      # Octopress
      def ask(message, valid_options)
        if valid_options
          answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /, '/')} ") until valid_options.include?(answer)
        else
          answer = get_stdin(message)
        end
        answer
      end

      def install_tasks
        namespace :rp_logs do
          desc "Create a new Jekyll site for RP logs, with the default theme"
          task :create_new_site, [:dir] do |t, args|
            if Dir.exist? args[:dir]
              if (Dir.entries(args[:dir]) - %w(. ..)).empty?
                puts "Using empty directory #{args[:dir]}"
              else
                fail "Directory #{args[:dir]} already exists, and is non-empty. Won't overwrite."
              end
            else
              mkdir_p args[:dir]
            end

            Dir.chdir(args[:dir]) do
              Rake::Task["rp_logs:bundler"].invoke
              Rake::Task["rp_logs:copy_theme"].invoke
            end
          end

          directory "_rps"

          file "Gemfile" do |tsk|
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

          task bundler: "Gemfile" do
            sh "bundle"
          end

          task :copy_theme do
            if File.directory?("_sass")
              abort("rake aborted!") if ask("A theme is already installed, proceeding will overwrite existing non-custom files. Are you sure?", ['y', 'n']) == 'n'
            end

            Rake::Task[:_rps].invoke
            # allow directory specification

            gem_root = Gem::Specification.find_by_name("jekyll-rp_logs").gem_dir
            cp_r Dir["#{gem_root}/.themes/default/source/*"], "./"
            copy_unless_exist("_config.yml.default", "_config.yml")
            touch "_sass/_custom-vars.scss"
            touch "_sass/_custom-rules.scss"
          end
        end
      end
    end
  end
end

Jekyll::RpLogs::RpTasks.new.install_tasks
