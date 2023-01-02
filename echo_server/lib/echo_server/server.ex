defmodule EchoServer.Server do
  require Logger

  def listen(port) when is_integer(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, :inet, port: port, active: false, reuseaddr: true])

    Logger.info("Listening for connections on port #{port}")

    accept(socket)
  end

  defp accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("Accepted new client connection")

    {:ok, pid} =
      Task.Supervisor.start_child(EchoServer.ClientSupervisor, fn ->
        Logger.info("Starting to serve new client.")
        serve(client)
      end)

    :gen_tcp.controlling_process(client, pid)

    Logger.info("Listening for further connections...")
    accept(socket)
  end

  defp serve(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    :gen_tcp.send(socket, data)
    serve(socket)
  end
end
