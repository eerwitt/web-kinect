require 'rack/websocket'

class EchoAction <  Rack::WebSocket::Application
  def on_open(env)
    puts "Client connected"
    EM.next_tick do
      @sub = EM::Hiredis.connect("redis://localhost:6379")

      @sub.subscribe "kinect_raw"
      # {:points => [{:x => 123, :y => 234, :z => 456}]}
      @sub.on(:message) do |channel,pixels| 
        puts "Got pixels #{pixels.length}"
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
