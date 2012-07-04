require 'freenect'

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
  puts depth.read_string_length(Freenect::DEPTH_11BIT_SIZE).unpack('S*').length
end

#dev.set_video_callback do |device, video, timestamp|
#  open_dump('r', timestamp, 'ppm') do |f|
#    f.puts("P6 %d %d 255\n" % [ Freenect::FRAME_W, Freenect::FRAME_H ] )
#    f.write(video.read_string_length(Freenect::RGB_SIZE))
#  end
#end

#while $record_running and (ctx.process_events >= 0)
#end

dev.stop_depth
dev.stop_video
dev.close
ctx.close
