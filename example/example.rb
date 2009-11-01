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

  pd.dsp = true
  sleep 3
  pd.dsp = false

  # add receive object for modify frequency of osc~
  freq = canvas.obj("r", "freq")
  line = canvas.obj("line")
  canvas.connect(freq.outlet, line.inlet)
  canvas.connect(line.outlet, osc.freq)

  pd.dsp = true
  pd.msg(:freq, 500, 4000)
  puts "freq 500 4000"
  sleep 3
  pd.msg(:freq, 220, 5000)
  puts "freq 220 5000"
  sleep 5
  pd.msg(:freq, 1000, 1000)
  puts "freq 1000 1000"
  sleep 1
  pd.msg(:freq, 100, 50)
  puts "freq 100 50"
  sleep 1
  pd.dsp = false
end
