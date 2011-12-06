require File.expand_path("#{File.dirname __FILE__}/node")
require File.expand_path("#{File.dirname __FILE__}/evaluation_context")

module CPN
  class CPN::Transition < Node
    attr_accessor :guard

    def enabled?
      valid_arc_token_combinations.length > 0
    end

    def ready?(at_time)
      d = min_distance_to_valid_combo(at_time)
      !d.nil? && d <= 0
    end

    def occur(at_time = 0)
      atcs = ready_arc_token_combinations(at_time)
      return nil if atcs.empty?
      arc_tokens = atcs.sample

      changed
      notify_observers(self, :start, true)

      context = ArcTokenBinding.as_context(arc_tokens)
      arc_tokens.each do |at|
        t = at.token
        at.arc.remove_token(t)
        t.ready_at(0) if t.respond_to? :ready_at
      end

      @outgoing.each do |arc|
        token = context.eval_output(arc.expr, at_time)
        arc.add_token(token) unless token.nil?
      end

      changed
      notify_observers(self, :end, enabled?)
      self
    end

    def min_distance_to_valid_combo(at_time)
      distances = valid_arc_token_combinations.map do |arc_tokens|
        arc_tokens.map { |binding| binding.ready_distance(at_time) }.max
      end
      [ distances.min, 0].max if distances.length > 0
    end

    def to_s
      "|#{@name}|"
    end

    def as_json
      hash = {
        :name => name,
        :enabled => enabled?
      }
      hash[:guard] = guard unless guard.nil?
      hash[:description] = description unless description.nil?
      hash[:x] = x unless x.nil?
      hash[:y] = y unless y.nil?
      hash
    end

    private

    def valid_arc_token_combinations
      ArcTokenBinding.all(@incoming).reject do |arc_tokens|
        context = ArcTokenBinding.as_context(arc_tokens)
        context.empty? || !context.eval_guard(@guard)
      end
    end

    # Return the list of enabled arc token combinations for which the ready distance is
    # the smallest.
    def ready_arc_token_combinations(at_time)
      min_combos = []
      min_value = nil 

      valid_arc_token_combinations.select do |arc_tokens|
        readies = arc_tokens.map { |binding| binding.ready_distance(at_time) }
        if readies.all? { |t| t <= 0 }
          if min_value.nil? || readies.min < min_value
            min_combos = [ arc_tokens ]
            min_value = readies.min
          elsif readies.min == min_value
            min_combos << arc_tokens
          end
        end
      end
      min_combos
    end
  end

  class ArcTokenBinding
    attr_accessor :token, :arc, :binding

    def initialize(arc, token)
      @token = token
      @arc = arc
      @binding = arc.token_binding(token)
    end

    def ready_distance(at_time)
      return ((@token.ready? || at_time) - at_time) if @token.respond_to?(:ready?)
      0
    end

    # Return all combinations of arc, token for each arc
    # So, for arcs A1[t1, t2], A2[t3, t4], A3[t5, t6]
    # will produce
    # [ [ [A1 t1], [A2 t3], [A3 t5] ]
    #   [ [A1 t1], [A2 t3], [A3 t6] ]
    #   [ [A1 t1], [A2 t4], [A3 t5] ]
    # etc. (all combinations)
    def self.all(arcs)
      return [] if arcs.length == 0
      first_ats = arcs.first.tokens.map { |t| ArcTokenBinding.new(arcs.first, t) }
      return [] if first_ats.length == 0
      return first_ats.map{|at| [ at ] }  if arcs.length == 1

      rest_cs = all(arcs[1..-1])

      result = []
      first_ats.each do |first_at| 
        rest_cs.map do |cs| 
          result << [ first_at ] + cs
        end
      end
      result
    end

    def self.as_context(arc_token_combinations)
      TransitionContext.by_merging(arc_token_combinations.map{|atc| atc.binding})
    end

  end
end

