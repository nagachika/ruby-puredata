require "puredata"

PureData.start(:port => 20001) do |pd|
  # osc~ => *~ 0.1 => dac~
  osc = pd.obj("osc~", 440)
  mul = pd.obj("*~", 0.3)
  dac = pd.obj("dac~")
  pd.connect(osc.outlet, mul.inlet(0))
  pd.connect(mul.outlet, dac.left)
  pd.connect(mul.outlet, dac.right)
  pd.dsp = true
  sleep 3
  pd.dsp = false

  # add receive object for modify frequency of osc~
  freq = pd.obj("r", "freq")
  line = pd.obj("line")
  pd.connect(freq.outlet, line.inlet)
  pd.connect(line.outlet, osc.freq)

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
end
