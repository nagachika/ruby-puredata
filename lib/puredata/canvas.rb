# vim:encoding=utf-8
#
# Ruby/PureData Canvas, Abstraction class

class PureData
  class Canvas
    def initialize(pd, name, opt={})
      @pd = pd
      @name = name.dup
      unless /\.pd\Z/ =~ @name
        @name += ".pd"
      end
      @dir = File.expand_path(opt[:dir] || Dir.pwd)
      @pdobjid = 0
      pos = opt[:position] || [100, 100]
      size = opt[:size] || [300, 300]
      font = opt[:font] || 10
      pd.msg("pd", "filename", @name, @dir)
      pd.msg("#N", "canvas #{pos.join(" ")} #{size.join(" ")} #{font}")
      pd.msg("#X", "pop", "1")
    end

    def msg(*args)
      @pd.msg("pd-#{@name}", *args)
    end

    def obj(klass, *args)
      self.msg("obj", 10, 10, klass, *args)
      id = @pdobjid
      @pdobjid += 1
      cls = PureData.dispatch_object_class(klass, *args)
      cls.new(@pd, self, id, klass, *args)
    end

    def connect(outlet, inlet)
      obj1, outletid = outlet.outlet_tuple
      obj2, inletid = inlet.inlet_tuple
      oid1 = obj1.pdobjid
      oid2 = obj2.pdobjid
      self.msg("connect", oid1, outletid, oid2, inletid)
    end

    def save(path=nil)
      if path
        name = File.basename(path)
        unless /\.pd\Z/ =~ name
          name += ".pd"
        end
        dir = File.expand_path(File.dirname(path))
      else
        name = @name
        dir = @dir
      end
      self.msg("savetofile", name, dir)
      @name = name
      @dir = dir
      nil
    end
  end

  class Abstraction < Canvas
    def initialize(pd, name, opt={})
      super(pd, name, opt)
      @inlets = []
      @outlets = []
    end

    def inlet(idx=0)
      @inlets[idx].outlet(0)
    end

    def outlet(idx=0)
      @outlets[idx].inlet(0)
    end

    def add_inlet(audio=false)
      if audio
        @inlets << self.obj("inlet~")
      else
        @inlets << self.obj("inlet")
      end
    end

    def add_outlet(audio=false)
      if audio
        @outlets << self.obj("outlet~")
      else
        @outlets << self.obj("outlet")
      end
    end

    def self.create(pd, name, opt={})
      abstract = self.new(pd, name, opt)
      yield(abstract)
      abstract.save
    end
  end
end
