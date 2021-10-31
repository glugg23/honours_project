package uk.ac.napier.util;

import jade.lang.acl.ACLMessage;

import java.io.Serializable;

public class Mail implements Serializable {
    private final ACLMessage message;
    private final int round;

    public Mail(ACLMessage message, int round) {
        this.message = message;
        this.round = round;
    }

    public ACLMessage getMessage() {
        return message;
    }

    public int getRound() {
        return round;
    }
}
