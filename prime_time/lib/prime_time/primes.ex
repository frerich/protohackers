defmodule PrimeTime.Primes do
  def prime?(2), do: true
  def prime?(3), do: true

  def prime?(n) when is_integer(n) and n > 1 do
    floored_sqrt = trunc(:math.sqrt(n))

    Enum.all?(2..floored_sqrt, &(rem(n, &1) != 0))
  end

  def prime?(_), do: false
end
