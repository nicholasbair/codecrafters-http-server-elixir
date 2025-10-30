defmodule Server do
  use Application

  alias Server.Connection, as: Conn
  alias Server.{
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
    |> Conn.new()
    |> serve()
    |> Router.route()
    |> Conn.maybe_close()

    handle_request(client)
  end

  @spec serve(Conn.t()) :: Conn.t()
  defp serve(%Conn{} = conn) do
    case Request.handle_request(conn) do
      {conn, :complete} -> conn
      {conn, :continue} -> serve(conn)
    end
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
