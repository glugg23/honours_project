defmodule MessageTest do
  use ExUnit.Case
  doctest Message

  test "creates correct message" do
    reference = IEx.Helpers.ref(0, 1, 2, 3)

    expected = %Message{
      performative: :inform,
      sender: :a,
      receiver: :b,
      reply_to: :a,
      content: :ok,
      conversation_id: reference
    }

    result = Message.new(:inform, :a, :b, :ok, reference)

    assert expected === result
  end

  test "replies to correct agent" do
    reference = IEx.Helpers.ref(0, 1, 2, 3)

    msg = %Message{
      performative: :inform,
      sender: {:a, :node1},
      receiver: {:b, :node2},
      reply_to: {:a, :node1},
      content: %{hello: :world},
      conversation_id: reference
    }

    expected = %Message{
      performative: :accept,
      sender: {:b, :node2},
      receiver: {:a, :node1},
      reply_to: {:b, :node2},
      content: :ok,
      conversation_id: reference
    }

    result = Message.reply(msg, :accept, :ok)

    assert expected === result
  end

  test "forwards to correct agent" do
    reference = IEx.Helpers.ref(0, 1, 2, 3)

    msg = %Message{
      performative: :inform,
      sender: {:a, :node1},
      receiver: {:b, :node2},
      reply_to: {:a, :node1},
      content: %{hello: :world},
      conversation_id: reference
    }

    expected = %Message{
      performative: :inform,
      sender: {:b, :node2},
      receiver: {:c, :node3},
      reply_to: {:a, :node1},
      content: %{hello: :world},
      conversation_id: reference
    }

    result = Message.forward(msg, {:c, :node3})

    assert expected === result
  end

  test "repling to a reply works" do
    reference = IEx.Helpers.ref(0, 1, 2, 3)

    msg = %Message{
      performative: :inform,
      sender: {:a, :node1},
      receiver: {:b, :node2},
      reply_to: {:a, :node1},
      content: %{price: 10},
      conversation_id: reference
    }

    expected = %Message{
      performative: :accept,
      sender: {:a, :node1},
      receiver: {:b, :node2},
      reply_to: {:a, :node1},
      content: %{price: 15},
      conversation_id: reference
    }

    msg = Message.reply(msg, :decline, %{price: 15})
    result = Message.reply(msg, :accept, %{price: 15})

    assert expected === result
  end

  test "forwards chaining messages works" do
    reference = IEx.Helpers.ref(0, 1, 2, 3)

    msg = %Message{
      performative: :inform,
      sender: {:a, :node1},
      receiver: {:b, :node2},
      reply_to: {:a, :node1},
      content: %{hello: :world},
      conversation_id: reference
    }

    expected = %Message{
      performative: :inform,
      sender: {:c, :node3},
      receiver: {:d, :node4},
      reply_to: {:a, :node1},
      content: %{hello: :world},
      conversation_id: reference
    }

    msg = Message.forward(msg, {:c, :node3})
    result = Message.forward(msg, {:d, :node4})

    assert expected === result
  end

  test "forwarding a reply works" do
    reference = IEx.Helpers.ref(0, 1, 2, 3)

    msg = %Message{
      performative: :inform,
      sender: {:a, :node1},
      receiver: {:b, :node2},
      reply_to: {:a, :node1},
      content: %{world: :hello},
      conversation_id: reference
    }

    expected = %Message{
      performative: :inform,
      sender: {:a, :node1},
      receiver: {:c, :node3},
      reply_to: {:b, :node2},
      content: %{world: :goodbye},
      conversation_id: reference
    }

    msg = Message.reply(msg, :inform, %{world: :goodbye})
    result = Message.forward(msg, {:c, :node3})

    assert expected === result
  end

  test "repling to a forwarded message works" do
    reference = IEx.Helpers.ref(0, 1, 2, 3)

    msg = %Message{
      performative: :inform,
      sender: {:a, :node1},
      receiver: {:b, :node2},
      reply_to: {:a, :node1},
      content: %{hello: :world},
      conversation_id: reference
    }

    expected = %Message{
      performative: :accept,
      sender: {:c, :node3},
      receiver: {:a, :node1},
      reply_to: {:c, :node3},
      content: :ok,
      conversation_id: reference
    }

    msg = Message.forward(msg, {:c, :node3})
    result = Message.reply(msg, :accept, :ok)

    assert expected === result
  end
end
