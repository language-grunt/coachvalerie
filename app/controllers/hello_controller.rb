class HelloController < ActionController::API
  def index
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    message = ActiveRecord::Base.connection.select_value("SELECT message FROM greetings WHERE id = 1")
    raise "Missing staging greeting" unless message == "hello world"
    render plain: "#{message}\n"
  end
end
