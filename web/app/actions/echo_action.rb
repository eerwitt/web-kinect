class EchoAction < Cramp::Websocket
  on_data :received_data

  def received_data(data)
    puts "GOTSDflJS"
    render "Got your #{data}"
  end
end
