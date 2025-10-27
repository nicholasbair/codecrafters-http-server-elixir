defmodule Server.Controller.FileController do
  @moduledoc """
  File controller
  """

  require Logger

  alias Server.{
    Connection,
    Response
  }

  @spec get_file(Connection.t(), String.t()) :: Connection.t()
  def get_file(%Connection{} = conn, filename) do
    file_path = Path.join(conn.temp_dir, filename)

    case File.read(file_path) do
      {:ok, content} -> Response.send(conn, :ok, content, "application/octet-stream")
      {:error, _} -> Response.send(conn, :not_found)
    end
  end

  @spec create_file(Connection.t(), String.t()) :: Connection.t()
  def create_file(%Connection{} = conn, filename) do
    file_path = Path.join(conn.temp_dir, filename)

    case File.write(file_path, conn.request.body) do
      :ok ->
        Response.send(conn, :created)
      {:error, err} ->
        Logger.error("Error creating file: #{inspect(err)}")
        Response.send(conn, :server_error)
    end
  end
end
