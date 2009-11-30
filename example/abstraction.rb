require "puredata"

Pd.start do |pd|
  # create abstraction "osc440.pd"
  sample = pd.abstraction("osc440") do |abst|
    abst.add_outlet(true)
    osc = abst.obj("osc~", 440)
    mul = abst.obj("*~", 0.3)
    osc >> mul
    abst.outlet(0) << mul
  end

  canvas = pd.canvas("sample")
  osc440 = canvas.obj("osc440")
  dac = canvas.obj("dac~")
  osc440 >> dac.left
  osc440 >> dac.right
  canvas.save

  pd.dsp = true
  sleep 3
  pd.dsp = false
end
