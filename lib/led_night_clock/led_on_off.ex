defmodule LedOnOff do
  use GenServer

  require Logger

  alias Circuits.GPIO

  @me __MODULE__
  @led1_control_output_pin Application.get_env(:led_night_clock, :led1_control_output_pin, 17)
  @led2_control_output_pin Application.get_env(:led_night_clock, :led2_control_output_pin, 27)
  @led3_control_output_pin Application.get_env(:led_night_clock, :led3_control_output_pin, 23)
  @led4_control_output_pin Application.get_env(:led_night_clock, :led4_control_output_pin, 24)
  @led5_control_output_pin Application.get_env(:led_night_clock, :led5_control_output_pin, 26)
  @led6_control_output_pin Application.get_env(:led_night_clock, :led6_control_output_pin, 6)
  @led7_control_output_pin Application.get_env(:led_night_clock, :led7_control_output_pin, 5)

  # CLIENT
  def start_link(_) do
    GenServer.start_link(@me, :noargs, name: @me)
  end

  def all_off() do
    switch_off(:one)
    switch_off(:two)
    switch_off(:three)
    switch_off(:four)
    switch_off(:five)
    switch_off(:six)
    switch_off(:seven)
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
    {:ok, output_gpio_5} = GPIO.open(@led5_control_output_pin, :output)
    {:ok, output_gpio_6} = GPIO.open(@led6_control_output_pin, :output)
    {:ok, output_gpio_7} = GPIO.open(@led7_control_output_pin, :output)

    Process.send_after(self(), {:init_sequence, :start}, 0)

    {:ok,
     %{
       pin1: output_gpio_1,
       pin2: output_gpio_2,
       pin3: output_gpio_3,
       pin4: output_gpio_4,
       pin5: output_gpio_5,
       pin6: output_gpio_6,
       pin7: output_gpio_7,
       led1_on: false,
       led2_on: false,
       led3_on: false,
       led4_on: false,
       led5_on: false,
       led6_on: false,
       led7_on: false
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
            [toggle_led_off(:four, state), :second_row_first]

          :second_row_first ->
            [toggle_led_on(:five, state), :second_row_second]

          :second_row_second ->
            [toggle_led_on(:six, state), :second_row_third]

          :second_row_third ->
            [toggle_led_on(:seven, state), :second_row_end]

          :second_row_end ->
            s1 = toggle_led_off(:five, state)
            s2 = toggle_led_off(:six, s1)
            s3 = toggle_led_off(:seven, s2)
            [s3, :end]
        end

      Process.send_after(self(), {:init_sequence, next_step}, 333)

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
      :five -> state.pin5
      :six -> state.pin6
      :seven -> state.pin7
    end
  end

  defp get_state_val(led) do
    case led do
      :one -> :led1_on
      :two -> :led2_on
      :three -> :led3_on
      :four -> :led4_on
      :five -> :led5_on
      :six -> :led6_on
      :seven -> :led7_on
    end
  end
end
