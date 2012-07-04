require 'rack/websocket'

class EchoAction <  Rack::WebSocket::Application
  def on_open(env)
    puts "Client connected"
    EM.next_tick do
      @pub = EM::Hiredis.connect("redis://localhost:6379")
      @sub = EM::Hiredis.connect("redis://localhost:6379")

      @sub.subscribe "kinect_raw"
      @sub.on(:message) do |channel,pixels| 
        send_data pixels
      end
    end
  end

  def on_close(env)
    puts "Closing"
    @pub.close_connection
    @sub.close_connection
  end

  def on_message(env, msg)
    puts "message: #{msg}"
  end

  def on_error(env, error)
    puts "Error #{error}"
  end
end
