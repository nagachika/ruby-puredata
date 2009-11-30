# vim:encoding=utf-8
#
# Ruby/PureData ojbect wrapper base class

class PureData

  @@pdclass = {}

  def self.register_pdobject(klass, *names)
    names.each do |n|
      @@pdclass[n] = klass
    end
  end

  def self.dispatch_object_class(klass, *args)
    cls = @@pdclass[klass.to_s]
    cls ||= PdObject
    cls
  end

  class PdObject
    def initialize(pd, canvas, pdobjid, name, *args)
      @pd = pd
      @canvas = canvas
      @pdobjid = pdobjid
      @name = name
      @args = args
    end
    attr_reader :canvas, :pdobjid, :name

    def inlet(idx=0)
      Inlet.new(self, idx)
    end

    def inlet_pair
      [self, 0]
    end

    def outlet(idx=0)
      Outlet.new(self, idx)
    end

    def outlet_pair
      [self, 0]
    end

    def <<(other)
      self.inlet << other
    end

    def >>(other)
      self.outlet >> other
    end
  end
end
