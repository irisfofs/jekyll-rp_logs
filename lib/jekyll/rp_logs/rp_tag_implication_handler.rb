module Jekyll
  module RpLogs
    class TagImplicationHandler
      class TagImplicationError < StandardError
      end

      attr_reader :tag_aliases, :tag_implications

      ##
      # Extract global settings from the config file.
      def initialize(config)
        @tag_implications = (config["tag_implications"] || {}).freeze
        @tag_aliases = (config["tag_aliases"] || {}).freeze
        validate_tag_rules
      end

      def update_tags(tag_set, verbose: false)
        removed_tags = Set.new
        loop do
          previous_tags = tag_set.clone
          cyclical = catch :cyclical_tags do
            implicate_tags(tag_set, removed_tags, verbose)
            alias_tags(tag_set, removed_tags)
            false
          end
          if cyclical
            fail_with "The tag #{cyclical[1]} (from #{cyclical[0]} => #{cyclical[1]}) has been removed before. There is a cycle in the tag aliases and implications."
          end
          # Break when there is no change in tags.
          return tag_set if tag_set == previous_tags
        end
      end

      private

      ##
      # Looks for various loops and other problems in the tag aliases and
      # implications.
      def validate_tag_rules
        # Check for aliases and implications from the same tag
        dupe = @tag_implications.keys.find { |k| @tag_aliases.key? k }
        if dupe
          fail_with "Tag \"#{dupe}\" is both aliased and implied from. Imply from the alias instead."
        end

        error_for_aliases_that_should_be_implications

        # Check for loooops.
        starter_tags = @tag_implications.keys.to_set.merge @tag_aliases.keys
        update_tags(starter_tags, verbose: true)
      end

      ##
      # Iteratively adds all implied tags until no more can be implied.
      # This method won't loop infinitely because there are only a finite
      # number of tag implications defined, and implications only add tags.
      # They can't remove tags.
      def implicate_tags(tag_set, removed_tags, verbose)
        tags_to_check = tag_set
        loop do
          # Because we use this set again as the tags to check we don't want
          # to clear it.
          to_add = Set.new
          tags_to_check.each do |tag|
            imply = @tag_implications.fetch(tag, [])

            removed, imply = imply.partition { |t| removed_tags.include? t }
            # It's okay if we want to imply a removed tag. Maybe?
            if verbose && !removed.empty?
              string = removed.size == 1 ? "is an aliased tag" : "are aliased tags"
              Jekyll.logger.warn "#{tag} implies #{removed}, which #{string}. Consider implying the alised tag directly."
            end

            to_add.merge imply
          end

          break if to_add.empty?
          tag_set.merge to_add
          tags_to_check = to_add
        end
      end

      ##
      # Iteratively apply tag aliases until no more can be applied
      def alias_tags(tag_set, removed_tags)
        tags_to_check = tag_set
        loop do
          to_add = Set.new
          tags_to_check.each do |tag|
            next unless @tag_aliases.key? tag

            aliased = @tag_aliases[tag]
            aliased.each do |t|
              next unless removed_tags.include? t
              throw(:cyclical_tags, [tag, t])
            end

            # if it's already in the set, something weird happened
            removed_tags << tag
            tag_set.delete tag
            to_add.merge aliased
          end

          break if to_add.empty?
          tag_set.merge to_add
          tags_to_check = to_add
        end
      end

      ##
      # Warn for aliases that include the original tag. They're equivalent to
      # implications.
      def error_for_aliases_that_should_be_implications
        error_messages = []
        @tag_aliases.each_pair do |k, v|
          if v.include? k
            error_messages << "Alias #{k} => #{v} is equivalent to an implication. #{k} will not be removed."
          end
        end
        fail_with error_messages.join("\n") unless error_messages.empty?
      end

      def fail_with(message)
        Jekyll.logger.error message
        fail TagImplicationError, message
      end
    end
  end
end
