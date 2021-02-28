import time
from spade.agent import Agent
from spade.behaviour import FSMBehaviour, State
from spade.message import Message

class Counter(Agent):
    class Hello(State):
        async def run(self):
            msg = Message(to="partner@localhost", body="Hello")
            await self.send(msg)

            msg = await self.receive(timeout=10)
            while msg is None:
                msg = await self.receive(timeout=10)
            
            print("[{}] found another agent {}".format(self.agent.jid, msg.sender))
            print("[{}] I'm {}".format(self.agent.jid, self.agent.jid))

            print("[{}] Starting to count".format(self.agent.jid))
            self.set_next_state("Count")
    
    class Count(State):
        async def on_start(self):
            time.sleep(1)

        async def run(self):
            print("[{}] count => {}".format(self.agent.jid, self.agent.count))

            if self.agent.count == 3:
                self.set_next_state("Die")
            else:
                self.agent.count += 1
                self.set_next_state("Count")

    class Die(State):
        async def run(self):
            print("[{}] orders Partner to die".format(self.agent.jid))
            msg = Message(to="partner@localhost", body="Die")
            await self.send(msg)
            self.kill(exit_code=0)

    async def setup(self):
        print("[{}] Starting".format(self.jid))
        self.count = 0

        self.behaviour = FSMBehaviour()
        self.behaviour.add_state(name="Hello", state=self.Hello(), initial=True)
        self.behaviour.add_state(name="Count", state=self.Count())
        self.behaviour.add_state(name="Die", state=self.Die())
        self.behaviour.add_transition(source="Hello", dest="Count")
        self.behaviour.add_transition(source="Count", dest="Count")
        self.behaviour.add_transition(source="Count", dest="Die")
        self.add_behaviour(self.behaviour)
