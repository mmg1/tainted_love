# frozen_string_literal: true

module TaintedLove
  class StackTrace
    BACKTRACE_LINE_REGEX = /^((?:[a-zA-Z]:)?[^:]+):(\d+)(?::in `([^']+)')?$/.freeze

    attr_accessor :stack_trace, :lines

    def initialize(stack_trace)
      @stack_trace = stack_trace
      @lines = stack_trace.map do |line|
        next unless line.match(BACKTRACE_LINE_REGEX)
        {
          file: Regexp.last_match(1),
          line_number: Regexp.last_match(2).to_i,
          method: Regexp.last_match(3),
        }
      end.compact

      # Hack to remove TaintedLove.proxy_method
      @lines.shift if @lines.first[:file]['tainted_love/utils.rb']
    end

    # Produces a hash from the stack trace to identify identical code path
    #
    # @return [String]
    def trace_hash
      lines = @lines.map { |line| "#{line[:file]}:#{line[:number]}" }.join(',')
      TaintedLove.hash(lines)
    end

    def to_json
      {
        trace_hash: trace_hash,
      }.to_json
    end

    # Create a new StackTrace object from the current thread backtrace
    #
    # @param skip [Integer] number of trace line to skip
    # @return [TaintedLove::StackTrace]
    def self.current(skip = 2)
      new(Thread.current.backtrace(skip))
    end
  end
end
