defmodule Server.Router do

  alias Server.{
    Connection,
    Controller.EchoController,
    Controller.FileController,
    Controller.PageController,
    Controller.UserAgentController,
    Response
  }

  @spec route(Connection.t()) :: Connection.t()
  def route(%Connection{request: %{method: "GET", request_target: "/files/" <> file}} = conn) do
    FileController.get_file(conn, file)
  end

  def route(%Connection{request: %{method: "POST", request_target: "/files/" <> file}} = conn) do
    FileController.create_file(conn, file)
  end

  def route(%Connection{request: %{method: "GET", request_target: "/echo/" <> param}} = conn) do
    EchoController.echo(conn, param)
  end

  def route(%Connection{request: %{method: "GET", request_target: "/user-agent"}} = conn) do
    UserAgentController.user_agent(conn)
  end

  def route(%Connection{request: %{method: "GET", request_target: "/"}} = conn) do
    PageController.index(conn)
  end

  def route(conn), do: Response.send(conn, :not_found)
end
