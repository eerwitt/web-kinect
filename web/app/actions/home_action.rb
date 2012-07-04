class HomeAction < Cramp::Action
  def start
    render Web::Application.haml(:index)
    finish
  end
end
