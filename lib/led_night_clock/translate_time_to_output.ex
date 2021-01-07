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

  def quarter(quarter) do
    GenServer.call(@me, {:quarter, quarter})
  end

  # SERVER
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:time, hour}, _from, state) do
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

  @impl true
  def handle_call({:quarter, quarter}, _from, state) do
    if quarter == 0 do
      LedOnOff.switch_off(:five)
      LedOnOff.switch_off(:six)
      LedOnOff.switch_off(:seven)
    end

    if quarter >= 1 do
      LedOnOff.switch_on(:five)
    end

    if quarter >= 2 do
      LedOnOff.switch_on(:six)
    end

    if quarter >= 3 do
      LedOnOff.switch_on(:seven)
    end

    {:reply, %{}, state}
  end
end
