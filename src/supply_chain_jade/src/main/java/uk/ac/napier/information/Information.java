package uk.ac.napier.information;

import jade.core.Agent;
import jade.domain.DFService;
import jade.domain.FIPAAgentManagement.DFAgentDescription;
import jade.domain.FIPAAgentManagement.ServiceDescription;
import jade.domain.FIPAException;
import jade.lang.acl.ACLMessage;
import uk.ac.napier.behaviours.GenServerBehaviour;

import java.util.logging.Level;
import java.util.logging.Logger;

public class Information extends Agent {
    final static Logger logger = Logger.getLogger(Information.class.getName());

    @Override
    protected void setup() {
        Object[] args = this.getArguments();
        String type = (String) args[0];

        DFAgentDescription description = new DFAgentDescription();
        description.setName(this.getAID());
        ServiceDescription service = new ServiceDescription();
        service.setName("information");
        service.setType(type);
        description.addServices(service);
        try {
            DFService.register(this, description);
        } catch(FIPAException e) {
            logger.log(Level.WARNING, "Failed to register information layer", e);
        }

        GenServerBehaviour behaviour = new GenServerBehaviour(this) {
            @Override
            public void handle(ACLMessage message) {
                System.out.println(message.getContent());
            }
        };

        this.addBehaviour(behaviour);
    }
}
