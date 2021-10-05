package uk.ac.napier;

import jade.core.Profile;
import jade.core.ProfileImpl;
import jade.core.Runtime;
import jade.wrapper.AgentContainer;
import jade.wrapper.AgentController;
import jade.wrapper.StaleProxyException;

import java.io.IOException;
import java.io.InputStream;
import java.util.logging.Level;
import java.util.logging.LogManager;
import java.util.logging.Logger;

public class Main {
    static Logger logger;

    static {
        InputStream stream = Main.class.getClassLoader().getResourceAsStream("logging.properties");
        try {
            LogManager.getLogManager().readConfiguration(stream);
            logger = Logger.getLogger(Main.class.getName());

        } catch(IOException e) {
            e.printStackTrace();
        }
    }

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

        Object[] typeArgs = new Object[]{type};

        try {
            switch(type) {
                case "clock": {
                    AgentController knowledge = container.createNewAgent("knowledge", "uk.ac.napier.knowledge.Clock", typeArgs);
                    AgentController behaviour = container.createNewAgent("behaviour", "uk.ac.napier.behaviour.Clock", null);
                    knowledge.start();
                    behaviour.start();
                    break;
                }
                case "manufacturer": {
                    AgentController knowledge = container.createNewAgent("knowledge", "uk.ac.napier.knowledge.Manufacturer", typeArgs);
                    AgentController behaviour = container.createNewAgent("behaviour", "uk.ac.napier.behaviour.Manufacturer", null);
                    knowledge.start();
                    behaviour.start();
                    break;
                }
                case "consumer": {
                    AgentController knowledge = container.createNewAgent("knowledge", "uk.ac.napier.knowledge.Consumer", typeArgs);
                    AgentController behaviour = container.createNewAgent("behaviour", "uk.ac.napier.behaviour.Consumer", null);
                    knowledge.start();
                    behaviour.start();
                    break;
                }
                case "producer": {
                    AgentController knowledge = container.createNewAgent("knowledge", "uk.ac.napier.knowledge.Producer", typeArgs);
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

            AgentController information = container.createNewAgent("information", "uk.ac.napier.information.Information", typeArgs);
            information.start();

        } catch(StaleProxyException e) {
            logger.log(Level.SEVERE, "Stale Proxy when creating agents", e);
        }
    }
}
