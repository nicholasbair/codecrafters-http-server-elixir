defmodule Server.Response do

  alias Server.Connection, as: Conn

  def send(%Conn{client: client}, :ok) do
    :ok = :gen_tcp.send(client, "HTTP/1.1 200 OK\r\n\r\n")
  end

  def send(%Conn{client: client}, :not_found) do
    :ok = :gen_tcp.send(client, "HTTP/1.1 404 Not Found\r\n\r\n")
  end
end
