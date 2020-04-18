defmodule BindTest do
  use ExUnit.Case
  doctest Bind

  test "greets the world" do
    assert Bind.hello() == :world
  end
end
