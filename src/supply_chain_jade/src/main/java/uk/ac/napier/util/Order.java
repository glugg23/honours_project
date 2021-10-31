package uk.ac.napier.util;

import jade.lang.acl.ACLMessage;

import java.io.Serializable;

public class Order implements Serializable {
    private final ACLMessage message;
    private final int round;
    private boolean accepted;

    public Order(ACLMessage message, int round, boolean accepted) {
        this.message = message;
        this.round = round;
        this.accepted = accepted;
    }

    public ACLMessage getMessage() {
        return message;
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
