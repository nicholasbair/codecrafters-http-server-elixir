defmodule Server.Request do

  alias Server.Connection

  @type t :: %__MODULE__{
    method: String.t(),
    request_target: String.t(),
    protocol: String.t(),
    headers: headers()
  }

  @type header :: String.t()
  @type headers :: %{optional(String.t()) => header()}

  defstruct [
    :method,
    :request_target,
    :protocol,
    headers: []
  ]

  @spec parse_request(Connection.t()) :: Connection.t()
  def parse_request(%Connection{raw_request: lines} = conn) do

    IO.inspect(lines)

    # TODO: this prob won't work for request bodies
    {[first], rest} =
      lines
      |> sanitize_lines()
      |> Enum.split(1)

    {method, target, protocol} = parse_method_target_protocol(first)
    headers = parse_headers(rest)

    req =
      %__MODULE__{
        method: method,
        request_target: target,
        protocol: protocol,
        headers: headers
      }

    %{conn | request: req}
  end

  @spec sanitize_lines([String.t()]) :: String.t()
  defp sanitize_lines(lines) do
    Enum.reduce(lines, [], fn line, acc ->
      case line do
        "\r\n" -> acc
        _ -> [String.replace(line, "\r\n", "") | acc ]
      end
    end)
  end

  @spec parse_method_target_protocol(String.t()) :: {String.t(), String.t(), String.t()}
  defp parse_method_target_protocol(line) do
    line
    |> String.split(" ", trim: true)
    |> List.to_tuple()
  end

  @spec parse_headers([String.t()]) :: headers()
  defp parse_headers(lines) do
    Enum.reduce(lines, %{}, fn line, acc ->
      line
      |> String.split(":", parts: 2)
      |> List.to_tuple()
      |> then(fn {k, v} -> Map.put(acc, k, v) end)
    end)
  end
end
