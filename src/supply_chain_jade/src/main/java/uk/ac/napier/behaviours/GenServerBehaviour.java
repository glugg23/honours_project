package uk.ac.napier.behaviours;

import jade.core.Agent;
import jade.core.behaviours.CyclicBehaviour;
import jade.lang.acl.ACLMessage;

public abstract class GenServerBehaviour extends CyclicBehaviour {
    public GenServerBehaviour() {
        super();
    }

    public GenServerBehaviour(Agent a) {
        super(a);
    }

    @Override
    public void action() {
        ACLMessage msg = myAgent.blockingReceive();
        handle(msg);
    }

    public abstract void handle(ACLMessage message);
}
