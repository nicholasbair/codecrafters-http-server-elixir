defmodule Server.Response do

  alias Server.Connection, as: Conn

  @status %{
    ok: {200, "OK"},
    created: {201, "Created"},
    not_found: {404, "Not Found"},
    server_error: {500, "Internal Server Error"}
  }

  @spec send(Conn.t(), atom()) :: Conn.t()
  def send(%Conn{client: client} = conn, status) do
    {code, desc} = Map.fetch!(@status, status)
    :ok = :gen_tcp.send(client, "HTTP/1.1 #{code} #{desc}\r\n\r\n")

    conn
  end

  @spec send(Conn.t(), atom(), String.t(), String.t()) :: Conn.t()
  def send(%Conn{client: client} = conn, status, body, content_type \\ "text/plain") do
    {code, desc} = Map.fetch!(@status, status)
    :ok = :gen_tcp.send(client,"HTTP/1.1 #{code} #{desc}\r\nContent-Type: #{content_type}\r\nContent-Length: #{String.length(body)}\r\n\r\n#{body}")

    conn
  end
end
