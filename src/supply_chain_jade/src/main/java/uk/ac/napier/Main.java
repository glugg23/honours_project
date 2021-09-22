package uk.ac.napier;

import jade.core.Profile;
import jade.core.ProfileImpl;
import jade.core.Runtime;
import jade.wrapper.AgentContainer;
import jade.wrapper.AgentController;
import jade.wrapper.StaleProxyException;

import java.util.logging.Level;
import java.util.logging.Logger;

public class Main {
    final static Logger logger = Logger.getLogger(Main.class.getName());

    public static void main(String[] args) {
        Runtime runtime = Runtime.instance();

        Profile profile = new ProfileImpl();
        String type = System.getenv("AGENT_TYPE");
        if(type == null) {
            type = "";
        }
        profile.setParameter(Profile.PLATFORM_ID, type);

        runtime.setCloseVM(true);
        AgentContainer container = runtime.createMainContainer(profile);

        try {
            switch(type) {
                case "clock": {
                    AgentController knowledge = container.createNewAgent("knowledge", "uk.ac.napier.knowledge.Clock", null);
                    AgentController behaviour = container.createNewAgent("behaviour", "uk.ac.napier.behaviour.Clock", null);
                    knowledge.start();
                    behaviour.start();
                    break;
                }
                case "manufacturer": {
                    AgentController knowledge = container.createNewAgent("knowledge", "uk.ac.napier.knowledge.Manufacturer", null);
                    AgentController behaviour = container.createNewAgent("behaviour", "uk.ac.napier.behaviour.Manufacturer", null);
                    knowledge.start();
                    behaviour.start();
                    break;
                }
                case "consumer": {
                    AgentController knowledge = container.createNewAgent("knowledge", "uk.ac.napier.knowledge.Consumer", null);
                    AgentController behaviour = container.createNewAgent("behaviour", "uk.ac.napier.behaviour.Consumer", null);
                    knowledge.start();
                    behaviour.start();
                    break;
                }
                case "producer": {
                    AgentController knowledge = container.createNewAgent("knowledge", "uk.ac.napier.knowledge.Producer", null);
                    AgentController behaviour = container.createNewAgent("behaviour", "uk.ac.napier.behaviour.Producer", null);
                    knowledge.start();
                    behaviour.start();
                    break;
                }
                default:
                    logger.severe("AGENT_TYPE not in [\"clock\", \"manufacturer\", \"consumer\", \"producer\"]");
                    container.kill();
                    return;
            }

            Object[] infoArgs = new Object[]{type};
            AgentController information = container.createNewAgent("information", "uk.ac.napier.information.Information", infoArgs);
            information.start();

        } catch(StaleProxyException e) {
            logger.log(Level.SEVERE, "Stale Proxy when creating agents", e);
        }
    }
}
