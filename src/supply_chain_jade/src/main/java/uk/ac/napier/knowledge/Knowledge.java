package uk.ac.napier.knowledge;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.TickerBehaviour;
import jade.domain.DFService;
import jade.domain.FIPAAgentManagement.DFAgentDescription;
import jade.domain.FIPAAgentManagement.ServiceDescription;
import jade.domain.FIPAException;
import jade.domain.FIPANames;

import java.io.FileInputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public abstract class Knowledge extends Agent {
    final static Logger logger = Logger.getLogger(Knowledge.class.getName());
    protected Properties properties = new Properties();
    protected boolean ready = false;
    protected int agentCount;
    protected ArrayList<String> agents = new ArrayList<>();

    @Override
    protected void setup() {
        Object[] args = this.getArguments();
        String type = (String) args[0];

        try(FileInputStream stream = new FileInputStream("src/main/resources/application.properties")) {
            properties.load(stream);

        } catch(Exception e) {
            logger.log(Level.SEVERE, "Failed to load application properties", e);
            throw new IllegalArgumentException("Failed to load application properties", e);
        }

        agentCount = Integer.parseInt(properties.getProperty("agentCount"));
        String[] agentArray = properties.getProperty("agents").split(",");
        Collections.addAll(agents, agentArray);
        agents.remove(type);

        TickerBehaviour behaviour = new TickerBehaviour(this, 1000) {
            private final ArrayList<AID> failedDfs = new ArrayList<>();
            private final DFAgentDescription ownDF = new DFAgentDescription();
            private ArrayList<AID> dfs = new ArrayList<>();

            @Override
            public void onStart() {
                for(String a : agents) {
                    AID aid = new AID(AID.createGUID("df", a), AID.ISGUID);
                    aid.addAddresses(String.format("http://%s:7778/acc", a));
                    dfs.add(aid);
                }

                ownDF.setName(myAgent.getDefaultDF());
                ServiceDescription service = new ServiceDescription();
                service.setName(myAgent.getDefaultDF().getLocalName());
                service.setType("fipa-df");
                service.addProtocols(FIPANames.InteractionProtocol.FIPA_REQUEST);
                service.addOntologies("fipa-agent-management");
                service.setOwnership("JADE");
                ownDF.addServices(service);
            }

            @Override
            protected void onTick() {
                for(AID df : dfs) {
                    try {
                        DFService.register(myAgent, df, ownDF);

                    } catch(FIPAException e) {
                        logger.log(Level.FINE, "Failed to register with " + df.getName(), e);
                        failedDfs.add(df);
                    }
                }

                dfs = new ArrayList<>(failedDfs);
                if(dfs.isEmpty()) {
                    ready = true;
                    this.stop();

                } else {
                    failedDfs.clear();
                }
            }
        };

        this.addBehaviour(behaviour);
    }
}
