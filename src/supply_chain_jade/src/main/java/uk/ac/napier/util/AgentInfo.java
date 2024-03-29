package uk.ac.napier.util;

import jade.core.AID;

import java.beans.XMLDecoder;
import java.beans.XMLEncoder;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.Serializable;
import java.util.HashMap;
import java.util.Properties;

public class AgentInfo implements Serializable {
    private String name;
    private String type;
    private String layer;
    private String address;
    private Boolean ignored;

    public AgentInfo() {
    }

    public AgentInfo(String name, String type, String layer, String address, Boolean ignored) {
        this.name = name;
        this.type = type;
        this.layer = layer;
        this.address = address;
        this.ignored = ignored;
    }

    /**
     * This main method generates an XML file that contains the connection details for all agents.
     * This can then be deserialized at runtime to load this information.
     *
     * @param args Ignores command line arguments
     * @throws IOException Does not handle any exceptions
     */
    public static void main(String[] args) throws IOException {
        String experiment = System.getenv("EXPERIMENT");
        String filepath = String.format("src/main/resources/%s.xml", experiment);

        Properties properties = new Properties();
        try(FileInputStream stream = new FileInputStream(String.format("src/main/resources/%s.properties", experiment))) {
            properties.load(stream);
        }

        HashMap<String, AgentInfo> agentInfo = new HashMap<>();
        String[] agents = properties.getProperty("agents").split(",");

        for(String a : agents) {
            String[] info = a.split(":");
            agentInfo.put(info[0], new AgentInfo(info[0], info[1], "information", String.format("http://%s:7778/acc", info[0]), false));
        }

        try(FileOutputStream stream = new FileOutputStream(filepath)) {
            try(XMLEncoder encoder = new XMLEncoder(stream)) {
                encoder.writeObject(agentInfo);
            }
        }
    }

    @SuppressWarnings("unchecked cast")
    public static HashMap<String, AgentInfo> load() throws IOException {
        String experiment = System.getenv("EXPERIMENT");
        String filepath = String.format("src/main/resources/%s.xml", experiment);

        try(FileInputStream stream = new FileInputStream(filepath)) {
            try(XMLDecoder decoder = new XMLDecoder(stream)) {
                Object result = decoder.readObject();
                return (HashMap<String, AgentInfo>) result;
            }
        }
    }

    public AID toAID() {
        AID aid = new AID(String.format("%s@%s", layer, name), AID.ISGUID);
        aid.addAddresses(address);
        return aid;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getLayer() {
        return layer;
    }

    public void setLayer(String layer) {
        this.layer = layer;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public Boolean getIgnored() {
        return ignored;
    }

    public void setIgnored(Boolean ignored) {
        this.ignored = ignored;
    }
}
