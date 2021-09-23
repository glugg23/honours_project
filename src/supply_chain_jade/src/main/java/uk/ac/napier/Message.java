package uk.ac.napier;

import jade.core.AID;
import jade.lang.acl.ACLMessage;

import java.util.UUID;

public class Message {
    public static ACLMessage newMsg(int perf, AID receiver, String content) {
        return newMsg(perf, receiver, content, UUID.randomUUID());
    }

    public static ACLMessage newMsg(int perf, AID receiver, String content, UUID conversationID) {
        ACLMessage message = new ACLMessage(perf);
        message.addReceiver(receiver);
        message.setContent(content);
        message.setConversationId(conversationID.toString());
        return message;
    }

    public static ACLMessage reply(ACLMessage message, int perf, String content) {
        ACLMessage reply = message.createReply();
        reply.setPerformative(perf);
        reply.setContent(content);
        return reply;
    }
}
