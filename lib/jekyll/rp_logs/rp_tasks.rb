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
          directory "_rps"

          desc "Create a new Jekyll site for RP logs, with the default theme"
          task :new do
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
