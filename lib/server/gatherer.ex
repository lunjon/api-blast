defmodule Blast.Gatherer do
  require Logger
  use GenServer
  alias Blast.Results

  @me Gatherer

  # API

  def result(url, status) do
    GenServer.cast(@me, {:result, url, status})
  end

  def done() do
    GenServer.cast(@me, :done)
  end

  # Server

  def start_link({url, worker_count, caller}) do
    GenServer.start_link(__MODULE__, {url, worker_count, caller}, name: @me)
  end

  def init({url, worker_count, caller}) do
    Process.send_after(self(), {:kickoff, url}, 0)
    {:ok, {worker_count, caller}}
  end

  def handle_cast(:done, {1, caller}) do
    send(caller, :done)
  end

  def handle_cast(:done, {worker_count, caller}) do
    {:noreply, {worker_count - 1, caller}}
  end

  def handle_cast({:result, url, status}, state) do
    Results.put(url, status)
    {:noreply, state}
  end

  def handle_info({:kickoff, url}, {worker_count, _} = state) do
    1..worker_count
    |> Enum.each(fn _ -> Blast.WorkerSupervisor.add_worker(url) end)

    {:noreply, state}
  end
end
