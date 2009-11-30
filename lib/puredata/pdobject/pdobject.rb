# vim:encoding=utf-8
#
# Ruby/PureData early scrach version.

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
    attr_reader :pdobjid, :name

    def inlet(idx=0)
      [self, idx]
    end

    def outlet(idx=0)
      [self, idx]
    end
  end
end
