class ReplProcess

  attr_accessor :timeout

  def initialize
    @pipe = nil
    @stopped = false
    @thread = nil
    @last_result
    self.start
    @timeout = 1
  end

  def stop
    @stopped = true
  end

  def start
    @stopped = false
    @pipe = IO.popen('irb', mode='r+')
  end

  def eval(a_string)
    puts "irb pid is #{@pipe.pid}"
    @pipe.write(a_string + "\n")
    sleep @timeout
    result = ''
    while true
      begin
        result += @pipe.read_nonblock(1024)
      rescue => e
        p e
        break
      end
    end
    p result
    result
  end

end

