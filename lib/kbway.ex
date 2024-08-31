defmodule Kbway do
  use Broadway

  alias Broadway.Message

  def hello do
    IO.puts("hello")
  end
end
