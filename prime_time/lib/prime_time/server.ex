defmodule PrimeTime.Server do
  require Logger

  alias PrimeTime.Primes

  def listen(port) when is_integer(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :line,
        buffer: 65536,
        port: port,
        active: false,
        reuseaddr: true
      ])

    Logger.info("Listening for connections on port #{port}")

    accept(socket)
  end

  defp accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(PrimeTime.ClientSupervisor, fn ->
        serve(client)
      end)

    :gen_tcp.controlling_process(client, pid)

    accept(socket)
  end

  defp serve(socket) do
    case read_json(socket) do
      {:ok, %{"method" => "isPrime", "number" => number}} when is_number(number) ->
        response = %{"method" => "isPrime", "prime" => Primes.prime?(number)}
        write_json(socket, response)
        serve(socket)

      _ ->
        write_json(socket, %{})
    end
  end

  defp read_json(socket) do
    with {:ok, data} <- :gen_tcp.recv(socket, 0) do
      Logger.info("<== #{inspect(data)}")
      Jason.decode(data)
    end
  end

  defp write_json(socket, payload) do
    data = Jason.encode!(payload)
    Logger.info("==> #{inspect(data)}")
    :gen_tcp.send(socket, data <> "\n")
  end
end
