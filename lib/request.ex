defmodule Server.Request do

  alias Server.Connection

  @type t :: %__MODULE__{
    method: String.t(),
    request_target: String.t(),
    protocol: String.t(),
    body: String.t(),
    headers: headers()
  }

  @type header :: String.t()
  @type headers :: %{optional(String.t()) => header()}

  defstruct [
    :method,
    :request_target,
    :protocol,
    :body,
    headers: %{}
  ]

  @spec parse_request(Connection.t()) :: Connection.t()
  def parse_request(%Connection{raw_request: raw} = conn) do
    [rest, body] = String.split(raw, "\r\n\r\n")
    [first | headers] = String.split(rest, "\r\n", trim: true)
    {method, target, protocol} = parse_method_target_protocol(first)
    parsed_headers = parse_headers(headers)

    req = %__MODULE__{
        method: method,
        request_target: target,
        protocol: protocol,
        headers: parsed_headers,
        body: body
      }

    %{conn | request: req}
  end

  @spec sanitize_line(String.t()) :: String.t()
  defp sanitize_line(line) do
    line
    |> String.replace("\r\n", "")
    |> String.trim()
  end

  @spec parse_method_target_protocol(String.t()) :: {String.t(), String.t(), String.t()}
  defp parse_method_target_protocol(line) do
    line
    |> String.split(" ")
    |> Enum.map(&sanitize_line/1)
    |> List.to_tuple()
  end

  @spec parse_headers([String.t()]) :: headers()
  defp parse_headers(lines) do
    Enum.reduce(lines, %{}, fn line, acc ->
      line
      |> String.split(":", parts: 2)
      |> Enum.map(&sanitize_line/1)
      |> List.to_tuple()
      |> then(fn {k, v} -> Map.put(acc, k, v) end)
    end)
  end
end
