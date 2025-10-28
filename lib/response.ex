defmodule Server.Response do

  alias Server.Connection, as: Conn
  alias Server.Request

  @status %{
    ok: {200, "OK"},
    created: {201, "Created"},
    not_found: {404, "Not Found"},
    server_error: {500, "Internal Server Error"}
  }

  @spec send(Conn.t(), atom()) :: Conn.t()
  def send(%Conn{client: client} = conn, status) do
    :ok =
      conn
      |> build_response(status)
      |> then(&:gen_tcp.send(client, &1))

    conn
  end

  @spec send(Conn.t(), atom(), String.t(), String.t()) :: Conn.t()
  def send(%Conn{client: client} = conn, status, body, content_type \\ "text/plain") do
    :ok =
      conn
      |> build_response(status, body, content_type)
      |> then(&:gen_tcp.send(client, &1))

    conn
  end

  @spec build_response(Conn.t(), atom()) :: String.t()
  defp build_response(%Conn{}, status) do
    build_request_line(status) <> "\r\n"
  end

  @spec build_response(Conn.t(), atom(), String.t(), String.t()) :: String.t()
  defp build_response(%Conn{} = conn, status, body, content_type) do
    build_request_line(status) <> build_headers(conn.request, content_type, String.length(body)) <> "\r\n#{body}"
  end

  @spec build_request_line(atom()) :: String.t()
  defp build_request_line(status) do
    {code, desc} = Map.fetch!(@status, status)
    "HTTP/1.1 #{code} #{desc}\r\n"
  end

  @spec build_headers(Request.t(), String.t(), integer()) :: String.t()
  defp build_headers(%Request{headers: %{"Accept-Encoding" => encoding}}, content_type, content_length) do
    case "gzip" in String.split(encoding, ",", trim: true) do
      true -> "Content-Type: #{content_type}\r\nContent-Length: #{content_length}\r\nContent-Encoding: gzip\r\n"
      false -> "Content-Type: #{content_type}\r\nContent-Length: #{content_length}\r\n"
    end
  end

  defp build_headers(%Request{}, content_type, content_length) do
    "Content-Type: #{content_type}\r\nContent-Length: #{content_length}\r\n"
  end
end
