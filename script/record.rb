$: << File.expand_path(File.join(File.dirname(__FILE__), "../libfreenect/wrappers/ruby/ffi-libfreenect/lib"))
require 'eventmachine'
require 'em-hiredis'
require 'freenect'
require 'json'
require 'lzma'

STDOUT.sync = true

class Kinect
  def initialize
    @ctx = Freenect.init()
    @dev = @ctx.open_device(0)
    @dev.set_depth_mode(Freenect::DEPTH_11BIT)
    @dev.set_video_mode(Freenect::VIDEO_RGB)

    @last_points = {}
  end

  def start(&block)
    @dev.start_depth()

    puts "Starting depth"
    @dev.set_depth_callback do |device, depth, timestamp|
      width = Freenect::FRAME_W
      height = Freenect::FRAME_H

      x = 0
      y = 1

      points = {}
      updated = 0

      puts "Reading depths"
      depth.read_string_length(Freenect::DEPTH_11BIT_SIZE).unpack('S*').each_with_index do |depth, i|
        if (i % width) == 0
          y += 1
          x = 0
        end
        x += 1

        if ((x % 10) == 0) and ((y % 10) == 0)
          points[x] = {} if not points.key?(x)

          current_depth = depth.to_f
          if not @last_points.key?(x) or not @last_points[x].key?(y) or not (current_depth > @last_points[x][y] - 10 and current_depth < @last_points[x][y] + 10)
            updated += 1
            points[x][y] = current_depth
          end
        end
      end

      @last_points = points
      puts "Points updated #{updated}"
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
    if (frames % 2) == 0
      @pub.publish("kinect_raw", LZMA.compress({:points => points}.to_json))
    end
  end

  @kinect.process

  trap('INT', 'TERM') do
    STDERR.puts "Caught INT signal cleaning up"
    @pub.close_connection
    @kinect.close
    EventMachine::stop_event_loop
  end
end
