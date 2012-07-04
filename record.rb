require 'ruby-debug'
$: << File.expand_path(File.join(File.dirname(__FILE__), "./ffi-libfreenect/lib"))
require 'eventmachine'
require 'em-hiredis'
require 'freenect'
require 'json'

$record_running = true

trap('INT') do
  STDERR.puts "Caught INT signal cleaning up"
  EventMachine::stop_event_loop
end

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

        #points << {:x => x, :y => y, :z => depth}
        if x == (width / 2).to_i and y == (height / 2).to_i
          points = [{:x => x, :y => y, :z => depth}]
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

kinect = Kinect.new
EventMachine::run do
  @pub = EM::Hiredis.connect("redis://localhost:6379")

  kinect.start do |points|
    puts "Publishing"
    @pub.publish("kinect_raw", {:points => points}.to_json)
  end

  kinect.process
end

kinect.close
