defmodule Server.Controller.UserAgentController do
  @moduledoc """
  User agent controller
  """

  alias Server.{
    Connection,
    Response
  }

  @spec user_agent(Connection.t()) :: Connection.t()
  def user_agent(%Connection{request: %{headers: headers}} = conn) do
    Response.send(conn, :ok, headers["User-Agent"])
  end
end
