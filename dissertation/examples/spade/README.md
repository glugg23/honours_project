# SPADE

A SPADE implementation of a counter agent.

This agent says hello to a partner, then counts to 3 and kills the partner agent.

## Setup

Ensure you have `prosody` installed.

```
prosodyctl register counter localhost password
prosodyctl register partner localhost password
prosodyctl start
```

```
virtualenv venv
source venv/bin/activate
pip3 install -r requirements.txt
```

## Run
```
python3 hello_agent.py
```
