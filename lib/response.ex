defmodule Server.Response do

  alias Server.Connection, as: Conn

  @status %{
    ok: {200, "OK"},
    not_found: {404, "Not Found"}
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
    # :ok = :gen_tcp.send(client, build_raw_response(code, desc, body, content_type))

    conn
  end

  # defp build_raw_response(code, desc, body, content_type) do
  #   """
  #   HTTP/1.1 #{code} #{desc}
  #   Content-Type: #{content_type}
  #   Content-Length: #{String.length(body)}

  #   #{body}
  #   """
  # end
end
