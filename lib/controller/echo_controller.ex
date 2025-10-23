defmodule Server.Controller.EchoController do

  alias Server.{
    Connection,
    Response
  }

  def echo(%Connection{} = conn) do
    # TODO: ideally this should be handled when casting the raw request into the req struct
    body =
      conn.request.request_target
      |> String.split("/", trim: true)
      |> List.last()

    Response.send(conn, :ok, body)
  end
end
