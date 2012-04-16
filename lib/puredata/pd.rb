# vim:encoding=utf-8
#
# Ruby/PureData early scrach version.

require "socket"

require "puredata/canvas"

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
    pd_params = opt[:pd_params]
    if path.nil? or not File.executable?(path)
      raise "option :pd_app_path (Pd-extended executable) must be specified."
    end
    cmd = [
      path,
      pd_params,
      "-nogui",
      "-send", "pd filename ruby-pd.pd ./;",
      "-send", "#N canvas 10 10 200 200 10;",
      "-send", "#X pop 1;",
      "-send", "pd-ruby-pd.pd obj 50 50 netreceive #{@portno} 0 old;",
    ].flatten
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
end

Pd = PureData
