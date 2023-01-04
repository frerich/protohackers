defmodule BudgetChat.Server do
  require Logger

  def listen(port) when is_integer(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :line,
        buffer: 65536,
        port: port,
        active: true,
        reuseaddr: true
      ])

    Logger.info("Listening for connections on port #{port}")

    accept(socket)
  end

  defp accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} = BudgetChat.Client.start(client)
    :gen_tcp.controlling_process(client, pid)

    accept(socket)
  end
end
