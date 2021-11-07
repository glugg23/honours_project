package uk.ac.napier.knowledge;

import jade.core.Agent;
import uk.ac.napier.util.AgentInfo;
import uk.ac.napier.util.State;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public abstract class Knowledge extends Agent {
    final static Logger logger = Logger.getLogger(Knowledge.class.getName());
    protected Properties properties = new Properties();
    protected State state;
    protected HashMap<String, AgentInfo> agents;
    private boolean isReady = false;

    @Override
    protected void setup() {
        Object[] args = this.getArguments();
        String type = (String) args[0];
        String experiment = System.getenv("EXPERIMENT");

        try(FileInputStream stream = new FileInputStream(String.format("src/main/resources/%s.properties", experiment))) {
            properties.load(stream);

        } catch(IOException e) {
            logger.log(Level.SEVERE, "Failed to load application properties", e);
            throw new IllegalArgumentException("Failed to load application properties", e);
        }

        state = new State(type);
        state.load(properties);

        try {
            agents = AgentInfo.load();

        } catch(IOException e) {
            logger.log(Level.SEVERE, "Failed to load agent info", e);
            throw new IllegalArgumentException("Failed to load agent info", e);
        }

        String filter = properties.getProperty(type + ".informationFilter");
        String[] informationFilter = filter.split(",");

        HashMap<String, AgentInfo> filteredAgents = new HashMap<>();

        for(Map.Entry<String, AgentInfo> kv : agents.entrySet()) {
            if(Arrays.stream(informationFilter).anyMatch(i -> kv.getValue().getType().equals(i))) {
                AgentInfo info = kv.getValue();
                info.setIgnored(true);
                filteredAgents.put(kv.getKey(), info);

            } else {
                filteredAgents.put(kv.getKey(), kv.getValue());
            }
        }

        agents = filteredAgents;
        this.isReady = true;
    }

    public boolean isReady() {
        return isReady;
    }

    public State getStateObject() {
        return state;
    }

    public void setStateObject(State state) {
        this.state = state;
    }

    public HashMap<String, AgentInfo> getInformationFilter() {
        return agents;
    }
}
