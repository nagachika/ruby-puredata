require "puredata"

PureData.start(:port => 10002) do |pd|
  # create canvas "sample.pd"
  canvas = pd.canvas("sample")

  # osc~ => *~ 0.1 => dac~
  osc = canvas.obj("osc~", 440)
  mul = canvas.obj("*~", 0.3)
  dac = canvas.obj("dac~")
  canvas.connect(osc.outlet, mul.inlet(0))
  canvas.connect(mul.outlet, dac.left)
  canvas.connect(mul.outlet, dac.right)

  # save canvas
  canvas.save

  # Canvas#save only messaging to Pd and there's no reply.
  # So we can't confirm Pd save patch to file.
  sleep 1
end
