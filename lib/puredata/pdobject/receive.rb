# vim:encoding=utf-8
#
# receive object class

class PureData
  class Receive < PdObject
    def msg(*args)
      @pd.msg(@args[0], *args)
    end
  end
end

PureData.register_pdobject(PureData::Receive, "receive", "r")
