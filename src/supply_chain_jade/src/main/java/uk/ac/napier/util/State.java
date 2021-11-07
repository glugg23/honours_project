package uk.ac.napier.util;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.stream.Collectors;

public class State implements Serializable {
    private final String type;
    private final HashMap<String, Integer> storage = new HashMap<>();
    private final HashMap<String, Integer> components = new HashMap<>();
    private final HashMap<String, Integer> computers = new HashMap<>();
    private final HashMap<String, HashMap<String, Integer>> recipes = new HashMap<>();
    private final HashMap<String, Order> orders = new HashMap<>();
    private HashMap<String, Mail> inbox = new HashMap<>();
    private int round = 0;
    private double money = 0;
    private int productionCapacity;
    private int producerCapacity;
    private int maximumQuantity;
    private String produces;

    public State(String type) {
        this.type = type;
    }

    public void load(Properties properties) {
        String componentString = properties.getProperty("components");
        String[] components = componentString.split(";");
        for(String c : components) {
            String[] component = c.split(",");
            this.components.put(component[0], Integer.parseInt(component[1]));
        }

        String computerString = properties.getProperty("computers");
        String[] computers = computerString.split(";");
        for(String c : computers) {
            String[] computer = c.split(",");
            this.computers.put(computer[0], Integer.parseInt(computer[1]));
        }

        String recipeString = properties.getProperty("recipes");
        String[] recipes = recipeString.split(";");
        for(String r : recipes) {
            String[] key = r.split(":");
            String[] recipeComponents = key[1].split("\\|");
            HashMap<String, Integer> values = new HashMap<>();
            for(String c : recipeComponents) {
                String[] value = c.split(",");
                values.put(value[0], Integer.parseInt(value[1]));
            }
            this.recipes.put(key[0], values);
        }

        String productionCapacity = properties.getProperty(this.type + ".productionCapacity", "-1");
        this.productionCapacity = Integer.parseInt(productionCapacity);

        String producerCapacity = properties.getProperty(this.type + ".producerCapacity", "-1");
        this.producerCapacity = Integer.parseInt(producerCapacity);

        String maximumQuantity = properties.getProperty(this.type + ".maximumQuantity", "-1");
        this.maximumQuantity = Integer.parseInt(maximumQuantity);

        String subtype = System.getenv("SUB_TYPE");

        if(subtype != null) {
            this.produces = properties.getProperty(subtype + ".produces", "");
        } else {
            this.produces = properties.getProperty(this.type + ".produces", "");
        }
    }

    public String getType() {
        return type;
    }

    public int getRound() {
        return round;
    }

    public void incrementRound() {
        ++round;
    }

    public HashMap<String, Integer> getStorage() {
        return storage;
    }

    public void putInStorage(String good, Integer quantity) {
        storage.put(good, quantity);
    }

    public HashMap<String, Mail> getInbox() {
        return inbox;
    }

    public void setInbox(HashMap<String, Mail> inbox) {
        this.inbox = inbox;
    }

    public void addToInbox(String key, Mail value) {
        inbox.put(key, value);
    }

    public void deleteInboxBeforeRound() {
        inbox = (HashMap<String, Mail>) inbox.entrySet()
                .stream()
                .filter(e -> e.getValue().getRound() >= round)
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    public HashMap<String, Order> getOrders() {
        return orders;
    }

    public void addOrder(String key, Order value) {
        orders.put(key, value);
    }

    public void setOrderStatus(String key, boolean status) {
        Order order = orders.get(key);
        order.setAccepted(status);
        orders.put(key, order);
    }

    public void deleteOrder(String key) {
        orders.remove(key);
    }

    public void addMoney(double amount) {
        money += amount;
    }

    public void subtractMoney(double amount) {
        money -= amount;
    }

    public HashMap<String, Integer> getComponents() {
        return components;
    }

    public HashMap<String, Integer> getComputers() {
        return computers;
    }

    public HashMap<String, HashMap<String, Integer>> getRecipes() {
        return recipes;
    }

    public int getProductionCapacity() {
        if(productionCapacity == -1) {
            throw new IllegalArgumentException("Invalid production capacity");
        }

        return productionCapacity;
    }

    public int getProducerCapacity() {
        if(producerCapacity == -1) {
            throw new IllegalArgumentException("Invalid producer capacity");
        }

        return producerCapacity;
    }

    public int getMaximumQuantity() {
        if(maximumQuantity == -1) {
            throw new IllegalArgumentException("Invalid maximum quantity");
        }

        return maximumQuantity;
    }

    public String getProduces() {
        if(produces.isEmpty()) {
            throw new IllegalArgumentException("Invalid produces value");
        }

        return produces;
    }
}
