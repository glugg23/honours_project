package uk.ac.napier.util;

import jade.lang.acl.ACLMessage;

import java.io.Serializable;

public class Mail implements Serializable {
    private final ACLMessage message;
    private final Request request;
    private final int round;

    public Mail(ACLMessage message, Request request, int round) {
        this.message = message;
        this.request = request;
        this.round = round;
    }

    public ACLMessage getMessage() {
        return message;
    }

    public Request getRequest() {
        return request;
    }

    public int getRound() {
        return round;
    }
}
