# vim:encoding=utf-8
#
# PureData connection (inlet/outlet) control

class PureData
  class IOlet
    def initialize(obj, idx=0)
      @obj = obj
      @idx = idx
    end

    attr_reader :idx

    def canvas
      @obj.canvas
    end

    def pdobjid
      @obj.pdobjid
    end

    def name
      @obj.name
    end

    def check_canvas(other)
      unless @obj.canvas == other.canvas
        raise "#{@obj.name} and #{other.name} must be in same canvas"
      end
    end

    def pair
      [@obj, @idx]
    end
  end

  class Inlet < IOlet
    def inlet_tuple
      [@obj, @idx]
    end

    def <<(other)
      if other.is_a?(PdObject)
        other = other.outlet
      end
      check_canvas(other)
      @obj.canvas.connect(other, self)
    end
  end

  class Outlet < IOlet
    def outlet_tuple
      [@obj, @idx]
    end

    def >>(other)
      if other.is_a?(PdObject)
        other = other.inlet
      end
      check_canvas(other)
      @obj.canvas.connect(self, other)
    end
  end

end
