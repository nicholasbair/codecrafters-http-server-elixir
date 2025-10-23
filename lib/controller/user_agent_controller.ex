defmodule Server.Controller.UserAgentController do

  alias Server.{
    Connection,
    Response
  }

  def user_agent(%Connection{request: %{headers: headers}} = conn) do
    Response.send(conn, :ok, headers["User-Agent"])
  end
end
