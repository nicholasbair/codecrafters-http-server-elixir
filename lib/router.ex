defmodule Server.Router do

  alias Server.{
    Connection,
    Controller.PageController,
    Controller.EchoController,
    Response
  }

  def route(%Connection{request: %{request_target: path}} = conn) do
    cond do
      String.match?(path, ~r/\/echo/) -> EchoController.echo(conn)
      String.match?(path, ~r/^\/$/) -> PageController.index(conn)
      true -> Response.send(conn, :not_found)
    end
  end
end
