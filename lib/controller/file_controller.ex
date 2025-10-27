defmodule Server.Controller.FileController do
  @moduledoc """
  File controller
  """

  alias Server.{
    Connection,
    Response
  }

  @spec get_file(Connection.t(), String.t()) :: Connection.t()
  def get_file(%Connection{} = conn, file) do
    file_path = Path.join(conn.temp_dir, file)

    case File.read(file_path) do
      {:ok, content} -> Response.send(conn, :ok, content, "application/octet-stream")
      {:error, _} -> Response.send(conn, :not_found)
    end
  end
end
