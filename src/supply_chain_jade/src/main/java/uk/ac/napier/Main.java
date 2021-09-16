package uk.ac.napier;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;

public class Main extends Agent {
    @Override
    protected void setup() {
        OneShotBehaviour behaviour = new OneShotBehaviour(this) {
            @Override
            public void action() {
                System.out.println("Hello from " + myAgent.getAID().getName());
                ACLMessage msg = new ACLMessage(ACLMessage.INFORM);
                AID aid = new AID("clock@clock_platform", AID.ISGUID);
                aid.addAddresses("http://clock:7778/acc");
                msg.addReceiver(aid);
                msg.setContent("Hello!");
                send(msg);

                for(int i = 0; i < 4; i++) {
                    ACLMessage reply = blockingReceive();
                    System.out.println(reply.getContent());
                }
            }
        };

        this.addBehaviour(behaviour);
    }
}
