defmodule Server.Controller.EchoController do
  @moduledoc """
  Echo controller
  """

  alias Server.{
    Connection,
    Response
  }

  @spec echo(Connection.t()) :: Connection.t()
  def echo(%Connection{} = conn) do
    # TODO: ideally this should be handled when casting the raw request into the req struct
    body =
      conn.request.request_target
      |> String.split("/", trim: true)
      |> List.last()

    Response.send(conn, :ok, body)
  end
end
