require 'rack/websocket'
require 'lzma'

STDOUT.sync = true

class EchoAction <  Rack::WebSocket::Application
  def on_open(env)
    puts "Client connected"
    @sub = EM::Hiredis.connect("redis://localhost:6379")
    @sub.subscribe "kinect_raw"

    EM.next_tick do
      @sub.on(:message) do |channel, raw_pixels| 
        puts "Got pixels"
        pixels = LZMA.decompress(raw_pixels)

        send_data pixels
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
