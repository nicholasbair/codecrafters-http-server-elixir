defmodule Server.Connection do

  alias Server.Request

  @type t :: %__MODULE__{
    client: port(),
    request: Request.t(),
    temp_dir: String.t(),
    raw_request: [String.t()]
  }

  defstruct [
    :client,
    :request,
    :temp_dir,
    raw_request: []
  ]

  @spec new(port(), String.t()) :: t()
  def new(client, temp_dir) do
    %__MODULE__{
      client: client,
      temp_dir: temp_dir
    }
  end

  @spec close(t()) :: :ok
  def close(conn), do: :gen_tcp.close(conn.client)
end
