# vim:encoding=utf-8
#
# Ruby/PureData early scrach version.

require "socket"

class PureData
  case RUBY_PLATFORM
  when /darwin/
    @@pd_app_path = "/Applications/Pd-extended.app/Contents/Resources/bin/pd"
  else
    @@pd_app_path = nil
  end

  def self.start(opt={}, &blk)
    pd = self.new(opt)
    pd.fork_pd(opt)
    pd.start(opt, &blk)
  end

  def self.attach(opt={}, &blk)
    pd = self.new(opt)
    pd.start(opt, &blk)
  end

  def initialize(opt={})
    @portno = (opt[:port] || 10002).to_i
  end

  def fork_pd(opt={})
    path = opt[:pd_app_path] || @@pd_app_path
    if path.nil? or not File.executable?(path)
      raise "option :pd_app_path (Pd-extended executable) must be specified."
    end
    cmd = [
      path,
      "-nogui",
      "-send", "pd filename ruby-pd.pd ./;",
      "-send", "#N canvas 10 10 200 200 10;",
      "-send", "#X pop 1;",
      "-send", "pd-ruby-pd.pd obj 50 50 netreceive #{@portno} 0 old;",
    ]
    @pid = fork do
      Process.setsid
      exec(*cmd)
    end
  end

  def bind(opt={})
    err = nil
    200.times do
      sleep 0.1
      begin
        @sock = TCPSocket.new("localhost", @portno)
        break
      rescue
        err = $!
      end
    end
    unless @sock
      $stderr.puts("connect to localhost:#{@portno} failed")
      raise err
    end
  end

  def start(opt={}, &blk)
    begin
      bind(opt)
      if blk
        blk.call(self)
      end
    ensure
      if blk
        stop
      end
    end
  end

  def stop
    if @sock
      @sock.close unless @sock.closed?
      @sock = nil
    end

    return if @pid.nil?

    begin
      Process.kill(:TERM, -@pid)
    rescue Errno::ESRCH
    rescue Errno::EPERM
      raise "fail to kill process(#{@pid}): #{$!}"
    end
    Process.waitpid(@pid)
  ensure
    @sock = nil
    @pid = nil
  end

  def msg(*args)
    @sock.puts(args.map{|l| l.to_s}.join(" ") + ";")
  end

  def canvas(name, opt={})
    Canvas.new(self, name, opt)
  end

  def abstraction(name, opt={}, &blk)
    if blk
      Abstraction.create(self, name, opt, &blk)
    else
      Abstraction.new(self, name, opt)
    end
  end

  def dsp=(flag)
    if flag
      self.msg("pd", "dsp", 1)
    else
      self.msg("pd", "dsp", 0)
    end
  end

  def quit
    self.msg("pd", "quit")
  end

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
      obj1, outletid = outlet
      obj2, inletid = inlet
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

  class PdObject
    def initialize(pd, canvas, pdobjid, name, *args)
      @pd = pd
      @canvas = canvas
      @pdobjid = pdobjid
      @name = name
      @args = args
    end
    attr_reader :pdobjid, :name

    def inlet(idx=0)
      [self, idx]
    end

    def outlet(idx=0)
      [self, idx]
    end
  end

  class Osc < PdObject
    def freq
      [self, 0]
    end
  end

  class Dac < PdObject
    def left
      [self, 0]
    end
    def right
      [self, 1]
    end
  end

  class Receive < PdObject
    def outlet
      [self, 0]
    end

    def msg(*args)
      @pd.msg(@args[0], *args)
    end
  end

  def self.dispatch_object_class(klass, *args)
    tbl = {
      "osc~" => Osc,
      "dac~" => Dac,
      "r" => Receive,
      "receive" => Receive,
    }
    cls = tbl[klass.to_s]
    cls ||= PdObject
    cls
  end
end

Pd = PureData
