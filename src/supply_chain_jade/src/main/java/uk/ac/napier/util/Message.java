package uk.ac.napier.util;

import jade.core.AID;
import jade.lang.acl.ACLMessage;

import java.io.IOException;
import java.io.Serializable;
import java.util.UUID;

public class Message {
    public static ACLMessage newMsg(int perf, AID receiver, String content) {
        return newMsg(perf, receiver, content, UUID.randomUUID());
    }

    public static ACLMessage newMsg(int perf, AID receiver, Serializable content) throws IOException {
        return newMsg(perf, receiver, content, UUID.randomUUID());
    }

    public static ACLMessage newMsg(int perf, AID receiver, String content, UUID conversationID) {
        ACLMessage message = new ACLMessage(perf);
        message.addReceiver(receiver);
        message.setContent(content);
        message.setConversationId(conversationID.toString());
        return message;
    }

    public static ACLMessage newMsg(int perf, AID receiver, Serializable content, UUID conversationID) throws IOException {
        ACLMessage message = new ACLMessage(perf);
        message.addReceiver(receiver);
        message.setContentObject(content);
        message.setConversationId(conversationID.toString());
        return message;
    }

    public static ACLMessage reply(ACLMessage message, int perf, String content) {
        ACLMessage reply = message.createReply();
        reply.setPerformative(perf);
        reply.setContent(content);
        return reply;
    }

    public static ACLMessage reply(ACLMessage message, int perf, Serializable content) throws IOException {
        ACLMessage reply = message.createReply();
        reply.setPerformative(perf);
        reply.setContentObject(content);
        return reply;
    }

    public static ACLMessage forward(ACLMessage message, AID receiver) {
        ACLMessage forward = newMsg(message.getPerformative(), receiver, message.getContent(),
                UUID.fromString(message.getConversationId()));
        forward.setSender(message.getSender());
        return forward;
    }
}
