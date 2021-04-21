defmodule Message do
  @moduledoc """
  This module defines a message structure for sending messages between agents.
  It is loosely based on FIPA ACL.
  """

  # TODO: Use specific atom values here once valid performatives have been decided
  @type performative :: atom()
  # Do not use pids for agents
  @type agent :: atom() | {atom(), node()}
  @type t :: %Message{
          performative: performative(),
          sender: agent(),
          receiver: agent(),
          reply_to: agent(),
          content: any(),
          conversation_id: reference()
        }

  @enforce_keys [:performative, :sender, :receiver, :reply_to, :content, :conversation_id]
  defstruct [
    :performative,
    :sender,
    :receiver,
    :reply_to,
    :content,
    :conversation_id
  ]

  @spec new(performative(), agent(), agent(), any(), reference()) :: Message.t()
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

  @spec reply(Message.t(), performative(), any()) :: Message.t()
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

  @spec forward(Message.t(), agent()) :: Message.t()
  def forward(msg, receiver) do
    %Message{msg | sender: msg.receiver, receiver: receiver}
  end
end
