defmodule Server do
  use Application

  alias Server.{
    Connection,
    Request,
    Router
  }

  def start(_type, _args) do
    System.argv()
    |> maybe_get_temp_dir()
    |> then(&Application.put_env(__MODULE__, :temp_dir, &1))

    children = [
      {Task.Supervisor, name: Server.RequestSupervisor},
      Supervisor.child_spec({Task, fn -> Server.listen() end}, restart: :permanent)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def listen() do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    # Since the tester restarts your program quite often, setting SO_REUSEADDR
    # ensures that we don't run into 'Address already in use' errors
    {:ok, listen_socket} = :gen_tcp.listen(4221, [:binary, packet: :line, active: false, reuseaddr: true])
    loop_acceptor(listen_socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Server.RequestSupervisor, fn -> handle_request(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
  end

  defp handle_request(client) do
    client
    |> Connection.new()
    |> serve()
    |> Router.route()

    handle_request(client)
  end

  @spec serve(Connection.t()) :: Connection.t()
  defp serve(%Connection{client: socket, raw_request: lines} = conn, bytes \\ nil) do
    new_line = read_data(socket, bytes)
    conn = %{conn | raw_request: lines <> new_line}

    case Request.handle_request(conn, new_line) do
      {conn, :complete} ->
        conn

      {conn, :continue_body} ->
        conn.request.headers
        |> Map.get("Content-Length")
        |> then(&serve(conn, &1))

      {conn, :continue} ->
        serve(conn)
    end
  end

  defp read_data(socket, nil), do: read_line(socket)
  defp read_data(socket, bytes), do: read_bytes(socket, bytes)

  @spec read_line(port()) :: String.t()
  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp read_bytes(socket, number) do
    :ok = :inet.setopts(socket, packet: 0)
    {:ok, data} = :gen_tcp.recv(socket, number, 5_000)
    data
  end

  defp maybe_get_temp_dir(["--directory", dir]), do: dir
  defp maybe_get_temp_dir(_), do: ""
end

defmodule CLI do
  def main(_args) do
    # Start the Server application
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)

    # Run forever
    Process.sleep(:infinity)
  end
end
