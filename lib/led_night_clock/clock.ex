defmodule Clock do
  use GenServer

  require Logger

  @me __MODULE__

  # CLIENT
  def start_link(_) do
    GenServer.start_link(@me, :noargs, name: @me)
  end

  # SERVER
  @impl true
  def init(_) do
    Process.send_after(self(), :get_time, 20_000)

    {:ok, %{last_hour: nil, last_quarter: nil}}
  end

  @impl true
  def handle_info(:get_time, state) do
    {:ok, now} = DateTime.now("Europe/Berlin")

    hour = determine_hour(now)
    quarter = determine_quarter(now)

    if hour != state.last_hour do
      TranslateTimeToOutput.time(hour)
    end

    if quarter != state.last_quarter do
      TranslateTimeToOutput.quarter(quarter)
    end

    Process.send_after(self(), :get_time, 60_000)

    {:noreply, %{state | last_hour: hour, last_quarter: quarter}}
  end

  defp determine_hour(now) do
    if now.year < 2021 do
      # No useful time yet, activate all outputs
      15
    else
      mod_hour = rem(now.hour, 12)

      if mod_hour == 0 do
        12
      else
        mod_hour
      end
    end
  end

  defp determine_quarter(now) do
    if now.year < 2021 do
      # No useful time yet, activate all outputs
      3
    else
      cond do
        now.minute < 15 -> 0
        now.minute < 30 -> 1
        now.minute < 45 -> 2
        true -> 3
      end
    end
  end
end
