module Jekyll
  module RpLogs
    ##
    # A `TagImplicationHandler` takes a set of tag implications and tag aliases
    # from a Jekyll config file and provides methods to update a set of tags to
    # include all of its (recursively) implicated and aliased tags.
    class TagImplicationHandler
      class TagImplicationError < StandardError
      end

      attr_reader :tag_aliases, :tag_implications

      ##
      # Extract global settings from the config file.
      def initialize(config)
        @tag_implications = (config["tag_implications"] || {}).freeze
        @tag_aliases = (config["tag_aliases"] || {}).freeze
       # validate_tag_rules #Temp Fix till big validations can be handled properly
      end

      ##
      # Iteratively apply tag implications and tag aliases until the list of
      # tags stops changing.
      def update_tags(tag_set, verbose: false)
        removed_tags = Set.new
        loop do
          previous_tags = tag_set.map{|t|t.to_s}

          implicate_tags(tag_set, removed_tags, verbose)
          alias_tags(tag_set, removed_tags)

          # Break when there is no change in tags.
          return tag_set if tag_set.map{|t|t.to_s} == previous_tags
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
          fail_with "Tag \"#{dupe}\" is both aliased and implied from. "\
                    "Imply from the alias instead."
        end

        error_for_aliases_that_should_be_implications

        # Check for loooops.
        starter_tags = Tag[@tag_implications.keys].to_set.merge Tag[@tag_aliases.keys]
        update_tags(starter_tags, verbose: true)
      end

      ##
      # Iteratively adds all implied tags until no more can be implied.
      # This method won't loop infinitely because there are only a finite
      # number of tag implications defined, and implications only add tags.
      # They can't remove tags.
      def implicate_tags(tag_set, removed_tags, verbose)
        until_tags_stabilize(tag_set) do |tag, to_add|
          imply = @tag_implications.fetch(tag.to_s, [])

          removed, imply = imply.partition { |t| removed_tags.include? t }
          # It's okay if we want to imply a removed tag. Maybe?
          if verbose && !removed.empty?
            string = removed.size == 1 ? "is an aliased tag" : "are aliased tags"
            Jekyll.logger.warn "#{tag} implies #{removed}, which #{string}. Consider implying "\
                               "the alised tag directly."
          end
          
          imply = Tag[imply]
          to_add.merge imply
        end
      end

      ##
      # Iteratively apply tag aliases until no more can be applied
      def alias_tags(tag_set, removed_tags)
        until_tags_stabilize(tag_set) do |tag, to_add|
          next unless @tag_aliases.key? tag.to_s
          aliased = @tag_aliases[tag.to_s]

          # If we are trying to alias back a tag already removed, there is a
          # cycle in the tag aliases and implications.
          removed = aliased.find { |t| removed_tags.include? t }
          error_for_cyclical_tags(tag.to_s, removed) if removed

          # if it's already in the set, something weird happened
          removed_tags << tag.to_s
          tag_set.delete tag
          aliased = Tag[aliased]
          aliased.each{|t| t.update_stats! tag.stats}
          to_add.merge aliased
          alias_loop = true
        end
      end

      def error_for_cyclical_tags(tag, removed_tag)
        fail_with "The tag #{removed_tag} (from #{tag} => #{removed_tag}) has "\
                  "been removed before. There is a cycle in the tag aliases "\
                  "and implications."
      end

      ##
      # Run the given block for each tag in tag_set, included tags added by
      # aliases or implications. If tag_set changes as a result of this, then
      # it runs again. This continues until there are no more aliases or
      # implications to add.
      def until_tags_stabilize(tag_set)
        tags_to_check = tag_set
        alias_loop = false
        loop do
          # Because we use this set again as the tags to check we don't want
          # to clear it.
          to_add = Set.new
          tags_to_check.each do |tag|
            yield(tag, to_add)
          end

          break if to_add.empty?
          if alias_loop
            tag_set = tag_set.to_a
            to_add.each{|t|
              index = tag_set.find_index{|v|v.eql? t}
              if index
                tag_set[index].update_stats t
              end
            }
            tag_set = tag_set.to_set
          end
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
            error_messages << "Alias #{k} => #{v} is equivalent to an implication. "\
                              "#{k} will not be removed."
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
