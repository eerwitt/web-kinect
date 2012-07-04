class HomeAction < Cramp::Action
  def start
    debugger
    render Web::Application.haml("index")
    finish
  end
end
