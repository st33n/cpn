require 'observer'

module CPN
  class Node
    include Observable

    attr_accessor :name, :container
    attr_accessor :incoming, :outgoing
    attr_accessor :properties

    def initialize(name)
      @name = name
      @incoming, @outgoing = [], []
      @properties = {}
    end

    def qname
      qn = name
      qn = "#{@container.qname}::#{qn}" if @container
      qn
    end

  end
end

