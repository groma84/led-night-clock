defmodule TranslateTimeToOutput do
  use GenServer
  use Bitwise

  require Logger

  @me __MODULE__

  # CLIENT
  def start_link(_) do
    GenServer.start_link(@me, :noargs, name: @me)
  end

  def time(hour) do
    GenServer.call(@me, {:time, hour})
  end

  # SERVER
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:time, hour}, _from, state) do
    # bits = Integer.digits(hour, 2)

    LedOnOff.all_off()

    if (hour &&& 1) == 1 do
      LedOnOff.switch_on(:one)
    end

    if (hour &&& 2) == 2 do
      LedOnOff.switch_on(:two)
    end

    if (hour &&& 4) == 4 do
      LedOnOff.switch_on(:three)
    end

    if (hour &&& 8) == 8 do
      LedOnOff.switch_on(:four)
    end

    {:reply, %{}, state}
  end
end
