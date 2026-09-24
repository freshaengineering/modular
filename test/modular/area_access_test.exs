defmodule Modular.AreaAccessTest do
  use ExUnit.Case
  doctest Modular.AreaAccess

  setup :verify_mocks

  defp verify_mocks(context) do
    Mox.set_mox_from_context(context)
    Mox.verify_on_exit!(context)
  end

  describe "define_mocks/0" do
    test "defines mock modules for behaviours" do
      Modular.AreaAccess.define_mocks()
      assert Code.ensure_loaded?(Modular.Test.Area.Mock)
    end

    test "is idempotent" do
      Modular.AreaAccess.define_mocks()
      Modular.AreaAccess.define_mocks()
    end
  end

  describe "install_stubs/0" do
    setup do
      Modular.AreaAccess.define_mocks()
      :ok
    end

    test "expectations take precedence and still reject excess calls" do
      Modular.AreaAccess.install_stubs()
      Mox.expect(Modular.Test.Area.Mock, :greet, fn _ -> "Expected" end)
      assert Modular.Test.Area.Mock.greet("Bob") == "Expected"

      assert_raise Mox.UnexpectedCallError, fn ->
        Modular.Test.Area.Mock.greet("Bob")
      end
    end

    test "reinstalling defaults preserves pending expectations" do
      Modular.AreaAccess.install_stubs()
      Mox.expect(Modular.Test.Area.Mock, :greet, fn _ -> "Expected" end)
      Mox.stub(Modular.Test.Area.Mock, :greet, fn _ -> "Custom" end)
      Modular.AreaAccess.install_stubs()
      assert Modular.Test.Area.Mock.greet("Bob") == "Expected"
      assert Modular.Test.Area.Mock.greet("Bob") == "Hello, Bob"
    end

    test "defaults remain isolated between owners" do
      Mox.set_mox_private()
      Modular.AreaAccess.install_stubs()
      parent = self()

      spawn_link(fn ->
        Modular.AreaAccess.install_stubs()
        Mox.stub(Modular.Test.Area.Mock, :greet, fn _ -> "Other owner" end)
        send(parent, {:other_owner, Modular.Test.Area.Mock.greet("Bob")})
      end)

      assert_receive {:other_owner, "Other owner"}
      assert Modular.Test.Area.Mock.greet("Bob") == "Hello, Bob"
    end

    test "stubs all functions with real implementations" do
      Modular.AreaAccess.define_mocks()
      Modular.AreaAccess.install_stubs()
      assert Code.ensure_loaded?(Modular.Test.Area.Mock)
      assert Modular.Test.Area.Mock.greet("Bob") == "Hello, Bob"
      assert Modular.Test.Area.Mock.incr(5) == 6
    end
  end
end
