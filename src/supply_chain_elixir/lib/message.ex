defmodule Message do
  @moduledoc """
  This module defines a message structure for sending messages between agents.
  It is loosely based on FIPA ACL.
  """

  @enforce_keys [:performative, :sender, :receiver, :reply_to, :content, :conversation_id]
  defstruct [
    :performative,
    :sender,
    :receiver,
    :reply_to,
    :content,
    :conversation_id
  ]

  def new(performative, sender, receiver, content, conversation_id \\ make_ref()) do
    %Message{
      performative: performative,
      sender: sender,
      receiver: receiver,
      reply_to: sender,
      content: content,
      conversation_id: conversation_id
    }
  end

  def reply(msg, performative, content) do
    %Message{
      msg
      | performative: performative,
        sender: msg.receiver,
        receiver: msg.reply_to,
        reply_to: msg.receiver,
        content: content
    }
  end

  def forward(msg, receiver) do
    %Message{msg | sender: msg.receiver, receiver: receiver}
  end
end
