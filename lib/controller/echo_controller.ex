defmodule Server.Controller.EchoController do
  @moduledoc """
  Echo controller
  """

  alias Server.{
    Connection,
    Response
  }

  @spec echo(Connection.t(), String.t()) :: Connection.t()
  def echo(%Connection{} = conn, param) do
    Response.send(conn, :ok, param)
  end
end
