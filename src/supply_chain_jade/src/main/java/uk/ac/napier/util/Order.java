package uk.ac.napier.util;

import jade.lang.acl.ACLMessage;

import java.io.Serializable;

public class Order implements Serializable {
    private final ACLMessage message;
    private final Request request;
    private final int round;
    private boolean accepted;

    public Order(ACLMessage message, Request request, int round, boolean accepted) {
        this.message = message;
        this.request = request;
        this.round = round;
        this.accepted = accepted;
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

    public boolean isAccepted() {
        return accepted;
    }

    public void setAccepted(boolean accepted) {
        this.accepted = accepted;
    }
}
