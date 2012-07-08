require 'rack/websocket'
require 'lzma'

STDOUT.sync = true

class EchoAction <  Rack::WebSocket::Application
  def on_open(env)
    puts "Client connected"
    @sub = EM::Hiredis.connect("redis://localhost:6379")
    @sub.subscribe "kinect_raw"

    EM.next_tick do
      # {:points => [{:x => 123, :y => 234, :z => 456}]}
      @sub.on(:message) do |channel,pixels| 
        puts "Got pixels #{pixels.length}"
        send_data LZMA.decompress(pixels)
      end
    end
  end

  def on_close(env)
    puts "Closing"
    @sub.close_connection
  end

  def on_message(env, msg)
    puts "message: #{msg}"
  end

  def on_error(env, error)
    puts "Error #{error}"
  end
end
