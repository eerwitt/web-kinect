require 'ruby-debug'
$: << File.expand_path(File.join(File.dirname(__FILE__), "./ffi-libfreenect/lib"))
require 'freenect'
require 'json'

$record_running = true

trap('INT') do
  STDERR.puts "Caught INT signal cleaning up"
  $record_running = false
end

ctx = Freenect.init()
dev = ctx.open_device(0)

dev.set_depth_mode(Freenect::DEPTH_11BIT)
dev.set_video_mode(Freenect::VIDEO_RGB)
dev.start_depth()
dev.start_video()

dev.set_depth_callback do |device, depth, timestamp|
  width = Freenect::FRAME_W
  height = Freenect::FRAME_H

  x = 0
  y = 1
  depth.read_string_length(Freenect::DEPTH_11BIT_SIZE).unpack('S*').each_with_index do |depth, i|
    if (i % width) == 0
      y += 1
      x = 0
    end
    x += 1

    puts({:x => x, :y => y, :z => depth}.to_json)
  end
end

#dev.set_video_callback do |device, video, timestamp|
#  open_dump('r', timestamp, 'ppm') do |f|
#    f.puts("P6 %d %d 255\n" % [ Freenect::FRAME_W, Freenect::FRAME_H ] )
#    f.write(video.read_string_length(Freenect::RGB_SIZE))
#  end
#end

while $record_running and (ctx.process_events >= 0)
end

dev.stop_depth
dev.stop_video
dev.close
ctx.close
