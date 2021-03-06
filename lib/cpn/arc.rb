module CPN

  # The Arc connects two nodes together, a state and a transition.
  # The optional expression is evaluated on entering the transition.
  class Arc
    attr_accessor :from, :to, :expr, :hints

    def initialize(from, to)
      @from, @to = from, to
    end

    # Return the binding for this arc with the given (input) token
    # e.g. token [1,2] and expression "a, b" returns an object o with o.a = 1 and o.b = 2 
    def token_binding(token)
      EvaluationContext.setup(expr, token)
    end

    def bindings_hash
      tokens.map { |token| token_binding(token).to_hash }
    end

    def to_s
      "#{@from.to_s} --#{(@expr && @expr.inspect) || '*'}--> #{@to.to_s}"
    end

    def tokens
      return [] unless @from.respond_to? :marking
      @from.marking
    end

    def remove_token(token)
      @from.remove_token(token)
    end

    def add_token(token)
      @to.add_token(token)
    end

    # This is used for building a data structure representable in JSON in the REST API
    def to_hash
      {:from => from.to_s, :to => to.to_s, :expr => expr.to_s }
    end

  end

end

