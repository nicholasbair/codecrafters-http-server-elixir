defmodule Server.Router do

  alias Server.{
    Connection,
    Response
  }

  def route(%Connection{request: req} = conn) do
    case req.request_target do
      "/" -> Response.send(conn, :ok)
      _ -> Response.send(conn, :not_found)
    end
  end

end
