package uk.ac.napier.behaviour;

import com.sun.management.OperatingSystemMXBean;
import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.util.*;

import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryUsage;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import static jade.lang.acl.MessageTemplate.*;

public class Manufacturer extends Agent {
    final static Logger logger = Logger.getLogger(Manufacturer.class.getName());
    private static final String START_ROUND = "startRound";
    private static final String HANDLE_NEW_ORDERS = "handleNewOrders";
    private static final String HANDLE_NEW_COMPONENTS = "handleNewComponents";
    private static final String HANDLE_COMPONENT_ORDERS = "handleComponentOrders";
    private static final String HANDLE_FINISHED_ORDERS = "handleFinishedOrders";
    private static final String SEND_FINISH_MSG = "sendFinishMsg";
    private State state;
    private ACLMessage roundMsg;

    @Override
    protected void setup() {
        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerFirstState(new StartRound(this), START_ROUND);
        fsm.registerState(new HandleNewOrders(this), HANDLE_NEW_ORDERS);
        fsm.registerState(new HandleNewComponents(this), HANDLE_NEW_COMPONENTS);
        fsm.registerState(new HandleComponentOrders(this), HANDLE_COMPONENT_ORDERS);
        fsm.registerState(new HandleFinishedOrders(this), HANDLE_FINISHED_ORDERS);
        fsm.registerState(new SendFinishMsg(this), SEND_FINISH_MSG);

        fsm.registerDefaultTransition(START_ROUND, HANDLE_NEW_ORDERS);
        fsm.registerDefaultTransition(HANDLE_NEW_ORDERS, HANDLE_NEW_COMPONENTS);
        fsm.registerDefaultTransition(HANDLE_NEW_COMPONENTS, HANDLE_COMPONENT_ORDERS);
        fsm.registerDefaultTransition(HANDLE_COMPONENT_ORDERS, HANDLE_FINISHED_ORDERS);
        fsm.registerDefaultTransition(HANDLE_FINISHED_ORDERS, SEND_FINISH_MSG);
        fsm.registerDefaultTransition(SEND_FINISH_MSG, START_ROUND);

        this.addBehaviour(fsm);
    }

    @SuppressWarnings("unchecked cast")
    protected void refreshInbox() {
        ACLMessage message = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "refreshInbox");
        send(message);
        ACLMessage reply = blockingReceive(MatchConversationId(message.getConversationId()));
        HashMap<String, Mail> newMessages = new HashMap<>();

        try {
            newMessages = (HashMap<String, Mail>) reply.getContentObject();
        } catch(UnreadableException | ClassCastException e) {
            logger.log(Level.WARNING, "Failed to deserialise inbox", e);
        }

        for(Map.Entry<String, Mail> msg : newMessages.entrySet()) {
            if(!state.getInbox().containsKey(msg.getKey())) {
                state.addToInbox(msg.getKey(), msg.getValue());
            }
        }
    }

    private static class StartRound extends OneShotBehaviour {
        private final Manufacturer manufacturer;

        public StartRound(Manufacturer a) {
            super(a);
            manufacturer = a;
        }

        @Override
        public void action() {
            manufacturer.roundMsg = manufacturer.blockingReceive(and(MatchPerformative(ACLMessage.INFORM),
                    MatchSender(new AID("behaviour@clock", AID.ISGUID))));

            ACLMessage stateRequest = Message.newMsg(ACLMessage.REQUEST, new AID("knowledge", AID.ISLOCALNAME), "state");
            manufacturer.send(stateRequest);
            ACLMessage reply = manufacturer.blockingReceive(MatchConversationId(stateRequest.getConversationId()));

            try {
                manufacturer.state = (State) reply.getContentObject();
            } catch(UnreadableException e) {
                logger.log(Level.WARNING, "Received invalid state", e);
            }
        }
    }

    private static class HandleNewOrders extends OneShotBehaviour {
        private final Manufacturer manufacturer;

        public HandleNewOrders(Manufacturer a) {
            super(a);
            manufacturer = a;
        }

        @Override
        public void action() {
            List<Mail> messages = manufacturer.state.getInbox().values().stream()
                    .filter(mail -> mail.getMessage().getPerformative() == ACLMessage.INFORM)
                    .filter(mail -> mail.getRequest().getType().equals("buying"))
                    .sorted(Comparator.comparing(Mail::getRequest).reversed())
                    .collect(Collectors.toList());

            int usedProduction = 0;
            ArrayList<Order> buyingRequests = new ArrayList<>(messages.size());

            for(Mail mail : messages) {
                if(acceptBuyingRequest(manufacturer.state, mail.getRequest(), usedProduction)) {
                    usedProduction += mail.getRequest().getQuantity();
                    buyingRequests.add(new Order(mail.getMessage(), mail.getRequest(), manufacturer.state.getRound(), true));
                } else {
                    buyingRequests.add(new Order(mail.getMessage(), mail.getRequest(), manufacturer.state.getRound(), false));
                }
            }

            buyingRequests.forEach(order -> {
                int perf = order.isAccepted() ? ACLMessage.ACCEPT_PROPOSAL : ACLMessage.REJECT_PROPOSAL;
                ACLMessage reply = Message.reply(order.getMessage(), perf, null);
                manufacturer.send(reply);
            });

            buyingRequests.stream().filter(Order::isAccepted).forEach(order ->
                    manufacturer.state.addOrder(order.getMessage().getConversationId(), order));
        }

        private boolean acceptBuyingRequest(State state, Request request, int usedProduction) {
            return canProduce(state, request, usedProduction) && acceptablePrice(state, request);
        }

        private boolean canProduce(State state, Request request, int usedProduction) {
            HashMap<String, Integer> computers = state.getComputers();
            return computers.containsKey(request.getGood())
                    && request.getQuantity() <= state.getProductionCapacity() - usedProduction;
        }

        private boolean acceptablePrice(State state, Request request) {
            HashMap<String, Integer> computers = state.getComputers();
            return request.getPrice() >= computers.get(request.getGood());
        }
    }

    private static class HandleNewComponents extends OneShotBehaviour {
        private final Manufacturer manufacturer;

        public HandleNewComponents(Manufacturer a) {
            super(a);
            manufacturer = a;
        }

        @Override
        public void action() {
            List<Order> orders = manufacturer.state.getOrders().values().stream()
                    .filter(o -> o.getRound() == manufacturer.state.getRound())
                    .collect(Collectors.toList());

            HashMap<String, Integer> requiredComponents = new HashMap<>();
            HashMap<String, HashMap<String, Integer>> recipes = manufacturer.state.getRecipes();

            for(Order o : orders) {
                int computerQuantity = o.getRequest().getQuantity();

                for(Map.Entry<String, Integer> component : recipes.get(o.getRequest().getGood()).entrySet()) {
                    Integer alreadyRequired = requiredComponents.getOrDefault(component.getKey(), 0);
                    Integer quantity = computerQuantity * component.getValue();
                    requiredComponents.put(component.getKey(), alreadyRequired + quantity);
                }
            }

            for(Map.Entry<String, Integer> component : requiredComponents.entrySet()) {
                List<Mail> sellingOrders = waitForSellingOrders(component.getKey());

                int amount = component.getValue();
                int producerCapacity = manufacturer.state.getProducerCapacity();
                for(int i = 0; i <= (component.getValue() / producerCapacity); ++i) {
                    Mail mail;
                    try {
                        mail = sellingOrders.get(i);
                    } catch(IndexOutOfBoundsException ignored) {
                        mail = sellingOrders.get(0);
                    }

                    int quantity = Math.min(amount, producerCapacity);
                    Request request = new Request("buying", component.getKey(), quantity,
                            mail.getRequest().getPrice(), manufacturer.state.getRound() + 2);

                    try {
                        ACLMessage message = Message.reply(mail.getMessage(), ACLMessage.REQUEST, request.intoString());
                        message.setSender(manufacturer.getAID("information"));
                        manufacturer.send(message);
                        manufacturer.state.addOrder(message.getConversationId(),
                                new Order(message, request, manufacturer.state.getRound(), false));

                        amount -= producerCapacity;

                    } catch(IOException e) {
                        logger.log(Level.WARNING, "Failed to serialise request", e);
                    }
                }
            }
        }

        private List<Mail> waitForSellingOrders(String good) {
            List<Mail> sellingOrders;
            do {
                sellingOrders = manufacturer.state.getInbox().values().stream()
                        .filter(m -> m.getMessage().getPerformative() == ACLMessage.INFORM)
                        .filter(m -> m.getRequest().getType().equals("selling"))
                        .filter(m -> m.getRequest().getGood().equals(good))
                        .sorted(Comparator.comparing(Mail::getRequest).reversed())
                        .collect(Collectors.toList());

                if(sellingOrders.isEmpty()) {
                    // Log this to indicate when race condition was met
                    logger.info("Selling orders was empty for: " + good);
                    manufacturer.refreshInbox();
                }

            } while(sellingOrders.isEmpty());

            return sellingOrders;
        }
    }

    private static class HandleComponentOrders extends OneShotBehaviour {
        private final Manufacturer manufacturer;

        public HandleComponentOrders(Manufacturer a) {
            super(a);
            manufacturer = a;
        }

        @Override
        public void action() {
            List<Mail> messages = manufacturer.state.getInbox().values().stream()
                    .filter(mail -> mail.getMessage().getPerformative() == ACLMessage.ACCEPT_PROPOSAL
                            || mail.getMessage().getPerformative() == ACLMessage.REJECT_PROPOSAL)
                    .collect(Collectors.toList());

            for(Mail m : messages) {
                if(m.getMessage().getPerformative() == ACLMessage.ACCEPT_PROPOSAL && m.getRequest() == null) {
                    manufacturer.state.setOrderStatus(m.getMessage().getConversationId(), true);

                } else if(m.getMessage().getPerformative() == ACLMessage.ACCEPT_PROPOSAL) {
                    Integer quantity = manufacturer.state.getStorage().getOrDefault(m.getRequest().getGood(), 0);
                    quantity += m.getRequest().getQuantity();
                    manufacturer.state.putInStorage(m.getRequest().getGood(), quantity);

                    manufacturer.state.subtractMoney(m.getRequest().getPrice() * m.getRequest().getQuantity());

                } else {
                    manufacturer.state.deleteOrder(m.getMessage().getConversationId());
                }
            }
        }
    }

    private static class HandleFinishedOrders extends OneShotBehaviour {
        private final Manufacturer manufacturer;

        public HandleFinishedOrders(Manufacturer a) {
            super(a);
            manufacturer = a;
        }

        @Override
        public void action() {
            List<Order> orders = manufacturer.state.getOrders().values().stream()
                    .filter(o -> o.getRequest().getType().equals("buying"))
                    .filter(o -> !o.getMessage().getSender().equals(manufacturer.getAID("information")))
                    .filter(o -> o.getRequest().getRound() == manufacturer.state.getRound() + 1)
                    .collect(Collectors.toList());

            HashMap<String, HashMap<String, Integer>> recipes = manufacturer.state.getRecipes();

            for(Order o : orders) {
                HashMap<String, Integer> components = recipes.get(o.getRequest().getGood());
                HashMap<String, Integer> requiredComponents = new HashMap<>();

                for(Map.Entry<String, Integer> kv : components.entrySet()) {
                    Integer quantity = kv.getValue() * o.getRequest().getQuantity();
                    requiredComponents.put(kv.getKey(), quantity);
                }

                boolean haveEnough = requiredComponents.entrySet().stream().allMatch(kv -> {
                    Integer inStorage = manufacturer.state.getStorage().getOrDefault(kv.getKey(), 0);
                    return inStorage >= kv.getValue();
                });

                if(haveEnough) {
                    Request request = new Request("delivery", o.getRequest().getGood(), o.getRequest().getQuantity(),
                            o.getRequest().getPrice(), manufacturer.state.getRound());
                    try {
                        ACLMessage message = Message.reply(o.getMessage(), ACLMessage.INFORM, request.intoString());
                        manufacturer.send(message);

                        manufacturer.state.addMoney(o.getRequest().getPrice() * o.getRequest().getQuantity());
                        manufacturer.state.deleteOrder(o.getMessage().getConversationId());

                        for(Map.Entry<String, Integer> kv : requiredComponents.entrySet()) {
                            manufacturer.state.putInStorage(kv.getKey(), -kv.getValue());
                        }

                    } catch(IOException e) {
                        logger.log(Level.WARNING, "Failed to serialise request", e);
                    }
                }
            }
        }
    }

    private static class SendFinishMsg extends OneShotBehaviour {
        private final Manufacturer manufacturer;

        public SendFinishMsg(Manufacturer a) {
            super(a);
            manufacturer = a;
        }

        @Override
        public void action() {
            try {
                ACLMessage stateMsg = Message.newMsg(ACLMessage.INFORM, new AID("knowledge", AID.ISLOCALNAME), manufacturer.state);
                manufacturer.send(stateMsg);
            } catch(IOException e) {
                logger.log(Level.WARNING, "Could not serialise state", e);
            }

            MemoryUsage heapMemoryUsage = ManagementFactory.getMemoryMXBean().getHeapMemoryUsage();
            MemoryUsage nonHeapMemoryUsage = ManagementFactory.getMemoryMXBean().getNonHeapMemoryUsage();
            long totalMemoryUsed = heapMemoryUsage.getUsed() + nonHeapMemoryUsage.getUsed();

            double cpuLoad = ManagementFactory.getPlatformMXBean(OperatingSystemMXBean.class).getProcessCpuLoad();

            logger.info(String.format("MEASURE=%d,%f,%d", manufacturer.state.getRound(), cpuLoad * 100, totalMemoryUsed));

            ACLMessage reply = Message.reply(manufacturer.roundMsg, ACLMessage.INFORM, "finished");
            manufacturer.send(reply);
        }
    }
}
