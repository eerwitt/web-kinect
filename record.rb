require 'ruby-debug'
$: << File.expand_path(File.join(File.dirname(__FILE__), "./libfreenect/wrappers/ruby/ffi-libfreenect/lib"))
require 'eventmachine'
require 'em-hiredis'
require 'freenect'
require 'json'

class Kinect
  def initialize
    @ctx = Freenect.init()
    @dev = @ctx.open_device(0)
    @dev.set_depth_mode(Freenect::DEPTH_11BIT)
    @dev.set_video_mode(Freenect::VIDEO_RGB)
  end

  def start(&block)
    @dev.start_depth()

    puts "Starting depth"
    @dev.set_depth_callback do |device, depth, timestamp|
      width = Freenect::FRAME_W
      height = Freenect::FRAME_H

      x = 0
      y = 1
      points = []
      puts "Reading depths"
      depth.read_string_length(Freenect::DEPTH_11BIT_SIZE).unpack('S*').each_with_index do |depth, i|
        if (i % width) == 0
          y += 1
          x = 0
        end
        x += 1

        if ((x % 10) == 0) and ((y % 10) == 0)
          # Converting depth to rgb normalized for testing
          points << {:x => x, :y => y, :z => (depth.to_f / 1000.0 * 255.0).round}
        end
      end

      block.call points
    end
  end

  def process
    EM.next_tick do
      @ctx.process_events
      process
    end
  end

  def close
    @dev.stop_depth
    @dev.close
    @ctx.close
  end
end

@kinect = Kinect.new
EventMachine::run do
  @pub = EM::Hiredis.connect("redis://localhost:6379")

  frames = 0
  @kinect.start do |points|
    frames += 1
    if (frames % 5) == 0
      puts "Publishing"
      @pub.publish("kinect_raw", {:points => points}.to_json)
    end
  end

  @kinect.process

  trap('INT') do
    STDERR.puts "Caught INT signal cleaning up"
    @pub.close_connection
    @kinect.close
    EventMachine::stop_event_loop
  end
end
