defmodule Server.Controller.PageController do
  @moduledoc """
  Page controller
  """

  alias Server.{
    Connection,
    Response
  }

  @spec index(Connection.t()) :: Connection.t()
  def index(%Connection{} = conn), do: Response.send(conn, :ok)
end
