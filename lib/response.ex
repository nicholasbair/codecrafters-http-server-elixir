defmodule Server.Response do

  alias Server.Connection, as: Conn

  @status %{
    ok: {200, "OK"},
    created: {201, "Created"},
    not_found: {404, "Not Found"},
    server_error: {500, "Internal Server Error"}
  }

  @supported_encoding "gzip"

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
  defp build_response(%Conn{} = conn, status) do
    close_header = maybe_send_close_header(conn)
    build_response_line(status) <> build_headers(close_header) <> "\r\n"
  end

  @spec build_response(Conn.t(), atom(), String.t(), String.t()) :: String.t()
  defp build_response(%Conn{request: %{headers: headers}} = conn, status, body, content_type) do
    accepted_encodings = Map.get(headers, "Accept-Encoding", [])
    close_header = maybe_send_close_header(conn)

    case should_encode_body?(accepted_encodings) do
      true ->
        encoded_body = :zlib.gzip(body)
        headers =
          build_headers([
            {"Content-Type", "#{content_type}"},
            {"Content-Length", "#{String.length(encoded_body)}"},
            {"Content-Encoding", @supported_encoding}
          ] ++ close_header)

        build_response_line(status) <> headers <> "\r\n#{encoded_body}"

      false ->
        headers =
          build_headers([
            {"Content-Type", "#{content_type}"},
            {"Content-Length", "#{String.length(body)}"}
          ] ++ close_header)

        build_response_line(status) <> headers <> "\r\n#{body}"
    end
  end

  @spec build_response_line(atom()) :: String.t()
  defp build_response_line(status) do
    {code, desc} = Map.fetch!(@status, status)
    "HTTP/1.1 #{code} #{desc}\r\n"
  end

  @spec build_headers([{String.t(), String.t()}]) :: String.t()
  defp build_headers(headers) when length(headers) > 0 do
    Enum.reduce(
      headers,
      "",
      fn {k, v}, acc ->
        acc <> "#{k}: #{v}\r\n"
      end
    )
  end
  defp build_headers(_), do: ""

  @spec should_encode_body?([String.t()]) :: boolean()
  defp should_encode_body?(accepted_encodings) do
    @supported_encoding in accepted_encodings
  end

  @spec maybe_send_close_header(Conn.t()) :: [{String.t(), String.t()}]
  defp maybe_send_close_header(%Conn{keep_alive?: true}), do: []
  defp maybe_send_close_header(%Conn{keep_alive?: false}), do: [{"Connection", "close"}]
end
