# vim:encoding=utf-8
#
# osc~ object class

class PureData
  class Osc < PdObject
    def freq
      inlet(0)
    end
  end
end
PureData.register_pdobject(PureData::Osc, "osc~")
