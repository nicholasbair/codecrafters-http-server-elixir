defmodule Server.Connection do

  alias Server.Request

  @type t :: %__MODULE__{
    client: port(),
    keep_alive?: boolean(),
    raw_request: String.t(),
    request: Request.t()
  }

  defstruct [
    :client,
    keep_alive?: true,
    raw_request: "",
    request: %Request{}
  ]

  @spec new(port()) :: t()
  def new(client) do
    %__MODULE__{
      client: client
    }
  end

  @spec maybe_close(t()) :: :ok
  def maybe_close(%__MODULE__{keep_alive?: true}), do: :ok
  def maybe_close(%__MODULE__{keep_alive?: false} = conn), do: :gen_tcp.close(conn.client)
end
