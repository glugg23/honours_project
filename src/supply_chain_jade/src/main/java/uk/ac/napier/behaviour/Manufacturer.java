package uk.ac.napier.behaviour;

import jade.core.AID;
import jade.core.Agent;
import jade.core.behaviours.FSMBehaviour;
import jade.core.behaviours.OneShotBehaviour;
import jade.lang.acl.ACLMessage;
import jade.lang.acl.UnreadableException;
import uk.ac.napier.util.*;

import java.io.IOException;
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
    private static final String SEND_FINISH_MSG = "sendFinishMsg";
    private State state;
    private ACLMessage roundMsg;

    @Override
    protected void setup() {
        FSMBehaviour fsm = new FSMBehaviour(this);

        fsm.registerFirstState(new StartRound(this), START_ROUND);
        fsm.registerState(new HandleNewOrders(this), HANDLE_NEW_ORDERS);
        fsm.registerState(new HandleNewComponents(this), HANDLE_NEW_COMPONENTS);
        fsm.registerState(new SendFinishMsg(this), SEND_FINISH_MSG);

        fsm.registerDefaultTransition(START_ROUND, HANDLE_NEW_ORDERS);
        fsm.registerDefaultTransition(HANDLE_NEW_ORDERS, HANDLE_NEW_COMPONENTS);
        fsm.registerDefaultTransition(HANDLE_NEW_COMPONENTS, SEND_FINISH_MSG);
        fsm.registerDefaultTransition(SEND_FINISH_MSG, START_ROUND);

        this.addBehaviour(fsm);
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

            // TODO: Race condition, inbox is a snapshot of messages and buying orders may not have arrived

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
                List<Mail> sellingOrders = manufacturer.state.getInbox().values().stream()
                        .filter(m -> m.getRequest().getType().equals("selling"))
                        .filter(m -> m.getRequest().getGood().equals(component.getKey()))
                        .sorted(Comparator.comparing(Mail::getRequest).reversed())
                        .collect(Collectors.toList());

                // TODO: Race condition, inbox is a snapshot of messages and selling orders may not have arrived
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
            manufacturer.state.deleteInboxBeforeRound();

            try {
                ACLMessage stateMsg = Message.newMsg(ACLMessage.INFORM, new AID("knowledge", AID.ISLOCALNAME), manufacturer.state);
                manufacturer.send(stateMsg);
            } catch(IOException e) {
                logger.log(Level.WARNING, "Could not serialise state", e);
            }

            ACLMessage reply = Message.reply(manufacturer.roundMsg, ACLMessage.INFORM, "finished");
            manufacturer.send(reply);
        }
    }
}
