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
    Process.send_after(self(), :get_time, 60_000)

    {:ok, %{last_hour: nil}}
  end

  @impl true
  def handle_info(:get_time, state) do
    {:ok, now} = DateTime.now("Europe/Berlin")

    hour =
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

    if (hour != state.last_hour) do
      TranslateTimeToOutput.time(hour)
    end

    Process.send_after(self(), :get_time, 60_000)

    {:noreply, %{state | last_hour: hour}}
  end
end
