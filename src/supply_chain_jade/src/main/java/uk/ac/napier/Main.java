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
        String platform = System.getenv("PLATFORM");
        String type = System.getenv("AGENT_TYPE");
        profile.setParameter(Profile.PLATFORM_ID, platform);

        runtime.setCloseVM(true);
        AgentContainer container = runtime.createMainContainer(profile);

        if(type == null) {
            type = "";
        }

        try {
            switch(type) {
                case "clock": {
                    AgentController a = container.createNewAgent("clock", "uk.ac.napier.MyAgent", null);
                    a.start();
                    break;
                }
                case "manufacturer": {
                    AgentController a = container.createNewAgent("manufacturer", "uk.ac.napier.MyAgent", null);
                    a.start();
                    break;
                }
                case "consumer": {
                    AgentController a = container.createNewAgent("consumer", "uk.ac.napier.MyAgent", null);
                    a.start();
                    break;
                }
                case "producer": {
                    AgentController a = container.createNewAgent("producer", "uk.ac.napier.MyAgent", null);
                    a.start();
                    break;
                }
                default:
                    logger.severe("AGENT_TYPE not in [\"clock\", \"manufacturer\", \"consumer\", \"producer\"]");
                    container.kill();
                    break;
            }

        } catch(StaleProxyException e) {
            logger.log(Level.SEVERE, "Stale Proxy when creating agents", e);
        }
    }
}
