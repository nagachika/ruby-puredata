# vim:encoding=utf-8
#
# Ruby/PureData early scrach version.

require "socket"

class PureData
  case RUBY_PLATFORM
  when /darwin/
    PD_APP_PATH="/Applications/Pd-extended.app/Contents/Resources/bin/pd"
  else
    raise "Sorry, Ruby/PureData now support only Mac OS X"
  end

  def self.start(opt={}, &blk)
    pd = self.new(opt)
    p pd.fork_pd(opt)
    pd.start(opt, &blk)
  end

  def self.attach(opt={}, &blk)
    pd = self.new(opt)
    pd.start(opt, &blk)
  end

  def initialize(opt={})
    @portno = (opt[:port] || 10002).to_i
    @pdobjid = 0
  end

  def fork_pd(opt={})
    path = opt[:pd_app_path] || PD_APP_PATH
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
      @sock.puts "pd filename ruby ./;"
      @sock.puts "#N canvas;"
      @sock.puts "#X pop 1;"
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

  def obj(klass, *args)
    @sock.puts("pd-ruby obj 10 10 #{klass} #{args.join(" ")};")
    id = @pdobjid
    @pdobjid += 1
    cls = dispatch_object_class(klass, *args)
    cls.new(self, id, klass, *args)
  end

  def connect(outlet, inlet)
    obj1, outletid = outlet
    obj2, inletid = inlet
    oid1 = obj1.pdobjid
    oid2 = obj2.pdobjid
    @sock.puts("pd-ruby connect #{oid1} #{outletid} #{oid2} #{inletid};")
  end

  def dsp=(flag)
    if flag
      @sock.puts("pd dsp 1;")
    else
      @sock.puts("pd dsp 0;")
    end
  end

  def msg(*args)
    @sock.puts(args.map{|l| l.to_s}.join(" ") + ";")
  end

  class PdObject
    def initialize(pd, pdobjid, name, *args)
      @pd = pd
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

  def dispatch_object_class(klass, *args)
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
