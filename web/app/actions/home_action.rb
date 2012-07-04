class HomeAction < Cramp::Action
  def start
    require 'haml'
    debugger
    render "TET"
    finish
  end
end
