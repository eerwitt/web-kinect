Cramp::Websocket.backend = :thin

class EchoAction < Cramp::Action
  self.transport = :websocket

  on_data :received_data

  def received_data(data)
    render "Got your #{data}"
  end
end
