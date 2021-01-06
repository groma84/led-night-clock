defmodule LedOnOff do
  use GenServer

  require Logger

  alias Circuits.GPIO

  @me __MODULE__
  @led1_control_output_pin Application.get_env(:led_night_clock, :led1_control_output_pin, 17)
  @led2_control_output_pin Application.get_env(:led_night_clock, :led2_control_output_pin, 27)
  @led3_control_output_pin Application.get_env(:led_night_clock, :led3_control_output_pin, 23)
  @led4_control_output_pin Application.get_env(:led_night_clock, :led4_control_output_pin, 24)

  # CLIENT
  def start_link(_) do
    GenServer.start_link(@me, :noargs, name: @me)
  end

  def all_off() do
    switch_off(:one)
    switch_off(:two)
    switch_off(:three)
    switch_off(:four)
  end

  def switch_on(led) do
    GenServer.call(@me, {:on, led})
  end

  def switch_off(led) do
    GenServer.call(@me, {:off, led})
  end

  # SERVER
  @impl true
  def init(_) do
    {:ok, output_gpio_1} = GPIO.open(@led1_control_output_pin, :output)
    {:ok, output_gpio_2} = GPIO.open(@led2_control_output_pin, :output)
    {:ok, output_gpio_3} = GPIO.open(@led3_control_output_pin, :output)
    {:ok, output_gpio_4} = GPIO.open(@led4_control_output_pin, :output)

    Process.send_after(self(), {:init_sequence, :start}, 0)

    {:ok,
     %{
       pin1: output_gpio_1,
       pin2: output_gpio_2,
       pin3: output_gpio_3,
       pin4: output_gpio_4,
       led1_on: false,
       led2_on: false,
       led3_on: false,
       led4_on: false
     }}
  end

  @impl true
  def handle_info({:init_sequence, step}, state) do
    if step != :end do
      [new_state, next_step] =
        case step do
          :start ->
            [toggle_led_on(:one, state), :one_to_two]

          :one_to_two ->
            [toggle_led_on(:two, state), :two_to_three]

          :two_to_three ->
            [toggle_led_on(:three, state), :three_to_four]

          :three_to_four ->
            [toggle_led_on(:four, state), :one_after_four]

          :one_after_four ->
            [toggle_led_off(:one, state), :two_after_four]

          :two_after_four ->
            [toggle_led_off(:two, state), :three_after_four]

          :three_after_four ->
            [toggle_led_off(:three, state), :four_after_four]

          :four_after_four ->
            [toggle_led_off(:four, state), :end]
        end

      Process.send_after(self(), {:init_sequence, next_step}, 250)

      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_call({:on, led}, _from, state) do
    {:reply, %{}, toggle_led_on(led, state)}
  end

  @impl true
  def handle_call({:off, led}, _from, state) do
    {:reply, %{}, toggle_led_off(led, state)}
  end

  defp toggle_led_on(led, state) do
    pin = get_pin(led, state)
    state_val = get_state_val(led)

    on(pin)

    %{state | state_val => true}
  end

  defp toggle_led_off(led, state) do
    pin = get_pin(led, state)
    state_val = get_state_val(led)

    off(pin)

    %{state | state_val => false}
  end

  defp on(gpio) do
    GPIO.write(gpio, 1)
  end

  defp off(gpio) do
    GPIO.write(gpio, 0)
  end

  defp get_pin(led, state) do
    case led do
      :one -> state.pin1
      :two -> state.pin2
      :three -> state.pin3
      :four -> state.pin4
    end
  end

  defp get_state_val(led) do
    case led do
      :one -> :led1_on
      :two -> :led2_on
      :three -> :led3_on
      :four -> :led4_on
    end
  end
end
