require "rake"

module Jekyll
  module RpLogs
    ##
    # Loads the gem's built-in rake tasks from tasks/rp_logs.rake
    class RpTasks
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        load "tasks/rp_logs.rake"
      end
    end
  end
end

Jekyll::RpLogs::RpTasks.new.install_tasks
