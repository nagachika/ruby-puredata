require "puredata"

PureData.start(:port => 10002) do |pd|
  # create abstraction "osc440.pd"
  sample = pd.abstraction("osc440") do |abst|
    abst.add_outlet(true)
    osc = abst.obj("osc~", 440)
    mul = abst.obj("*~", 0.3)
    abst.connect(osc.outlet, mul.inlet)
    abst.connect(mul.outlet, abst.outlet(0))
  end

  canvas = pd.canvas("sample")
  osc440 = canvas.obj("osc440")
  dac = canvas.obj("dac~")
  canvas.connect(osc440.outlet, dac.left)
  canvas.connect(osc440.outlet, dac.right)
  canvas.save

  pd.dsp = true
  sleep 3
  pd.dsp = false
end
