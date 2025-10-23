defmodule Server.Controller.PageController do
  alias Server.{
    Connection,
    Response
  }

  def index(%Connection{} = conn), do: Response.send(conn, :ok)
end
