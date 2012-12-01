class ReplProcess

  attr_accessor :timeout

  def initialize
    @pipe = nil
    @status = nil
    @thread = nil
    @last_result

    @timeout = 1
    @rails_dir = '~/Documents/HPI/ProgMod/rails-example'

    self.start
  end

  def stop
    @status = :stopped
  end

  def start
    cmd = "bash -c 'source ~/.profile && cd #{@rails_dir} && rails console'"
    puts cmd
    @pipe = IO.popen(cmd, mode='r+')
    sleep 10
    p @pipe.read_nonblock(1024)
    self.starting
  end

  def starting
    @stopped = :starting

    # @pipe.write will block as long as rails is still loading
    @pipe.write("\n")
    @pipe.write("require('#{File.join(Dir.getwd, 'lib', 'require.rb')}')\n")

    p "Rails loaded, ready for action"

    @status = :running
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
