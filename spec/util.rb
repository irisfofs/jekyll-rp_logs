module Jekyll
  module RpLogs
    ##
    # Provides utility methods for test suites.
    class Util
      # Sets up the dev_site directory for tests to use, by invoking the
      # rake deploy task.
      #
      # Returns an option hash to use as a Jekyll config by merging the
      # _config.yml file with Jekyll's own configuration defaults.
      def self.gross_setup_stuff
        # Pretty sure this is gross
        deploy

        Dir.chdir("dev_site") do
          return Jekyll::Configuration::DEFAULTS.merge(
            "source" => "./").merge YAML.load_file("_config.yml")
        end
      end

      VALID_TEST_NAMES =
        %w(test test_arc_name test_extension test_infer_char_tags test_options
           test_disable_liquid test_tag_implication
           test_mirc test_skype12 test_skype24 test_description).freeze

      EXISTING_TAGS =
        %w(_developer_s_quote_test_ test John dolor lorem_ipsum noncanon Eve
           Alice Bob).freeze

      private_class_method def self.deploy
        # Rake will eat the ARGV otherwise
        # https://github.com/jimweirich/rake/issues/277
        # Perhaps it doesn't exactly "eat" it but still, it shouldn't think that
        # rspec's command line arguments are its own
        orig_argv = ARGV.dup
        ARGV.replace([])
        Rake.application.init
        ARGV.replace(orig_argv)

        Rake.application.load_rakefile
        Rake.application.options.verbose = false
        Rake::Task["deploy"].invoke
      end
    end
  end
end
