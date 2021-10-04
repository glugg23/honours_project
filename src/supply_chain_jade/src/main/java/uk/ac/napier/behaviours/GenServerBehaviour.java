package uk.ac.napier.behaviours;

import jade.core.Agent;
import jade.core.behaviours.SimpleBehaviour;
import jade.lang.acl.ACLMessage;

public abstract class GenServerBehaviour extends SimpleBehaviour {
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

    /**
     * This makes the GenServerBehaviour cyclic by always returning false.
     * However, unlike CyclicBehaviour this function is not final and so can be overridden.
     *
     * @return Always returns false.
     */
    @Override
    public boolean done() {
        return false;
    }
}
