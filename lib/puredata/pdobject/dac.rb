# vim:encoding=utf-8
#
# dac~ object class

class PureData
  class Dac < PdObject
    def left
      inlet(0)
    end
    def right
      inlet(1)
    end
  end
end

PureData.register_pdobject(PureData::Dac, "dac~")
