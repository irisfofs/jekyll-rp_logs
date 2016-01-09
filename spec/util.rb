module Jekyll
  module RpLogs
    class Util
      def self.gross_setup_stuff
        # Pretty sure this is gross

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

        Dir.chdir("dev_site") do
          return Jekyll::Configuration::DEFAULTS.merge(
            "source" => "./").merge YAML.load_file("_config.yml")
        end
      end

      VALID_TEST_NAMES =
        %w(test test_arc_name test_extension test_infer_char_tags test_options
           test_disable_liquid test_tag_implication
           test_mirc test_skype12 test_skype24).freeze
    end
  end
end
