module Jekyll
  module RpLogs
    class Parser
      FORMAT_STR = nil

      # These patterns are reasonably universal.
      # (?<foo>pattern) is a named group accessible via $LAST_MATCH_INFO[:foo]

      # IRC mode characters for most IRCds.
      MODE = /(?<mode>[+%@&~!]?)/

      # The allowable characters in nicks. Errs on the side of being permissive
      # rather than restrictive
      NICK = /(?<nick>[\w\-\\\[\]\{\}\^\`\|]+)/

      # Match flags used for forcing the parser to treat the line a certain way
      FLAGS = /(?<flags>(?:![A-Z]+ )*)/
    end
  end
end
