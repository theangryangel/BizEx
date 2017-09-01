defmodule BizExTest do
  use ExUnit.Case
  doctest BizEx

  test "greets the world" do
    assert BizEx.hello() == :world
  end
end
