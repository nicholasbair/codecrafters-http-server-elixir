defmodule Server.Response do

  alias Server.Connection, as: Conn

  @status %{
    ok: {200, "OK"},
    not_found: {404, "Not Found"}
  }

  def send(%Conn{client: client}, status) do
    {code, desc} = Map.fetch!(@status, status)
    :ok = :gen_tcp.send(client, "HTTP/1.1 #{code} #{desc}\r\n\r\n")
  end

  def send(%Conn{client: client}, status, body) do
    {code, desc} = Map.fetch!(@status, status)

    # TODO: ideally, don't hardcode content type here
    :ok = :gen_tcp.send(client,"HTTP/1.1 #{code} #{desc}\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(body)}\r\n\r\n#{body}")
  end
end
