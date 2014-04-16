# ZestPhone [![Build Status](https://travis-ci.org/ZestFinance/zestphone.svg?branch=master)](https://travis-ci.org/ZestFinance/zestphone) [![Code Climate](https://codeclimate.com/github/ZestFinance/zestphone.png)](https://codeclimate.com/github/ZestFinance/zestphone)

## What is ZestPhone?
Zestphone is a telephony call center agent-coordination software.
ZestPhone is a drop-in phone widget that can be simply added to any web application to give you full call center functionality.  
ZestPhone uses Twilio for calls, and uses Pusher to synchronize call states across multiple agents.  

### Features
- Inbound and outbound calling
- Call outbound to anywhere in the world*
- Cold and warm transfers
- Put a call on hold / resume a call
- Agent status / presence
- Ability to respond to telephony events in your application
- Uses existing agent names/numbers/ids
- Embeds into your existing javascript-enabled application
- PSTN or VoIP (i.e. use a regular phone, SIP, or twilio client)
- Call recording and storage
- Voicemail
- History and auditing

### Why use ZestPhone 

Am I (or my company) a good candidate?

- **Quick integration** You want to quickly and easily add phone capabilities to your application
- **1:1 Customer Service Experience** You want to empower your call center agents to provide 1:1 support to customers with easy-to-use transfer and voicemail capabilities
- **Use any type of phone** You have call centers with different phone setups and want software to support them all (PSTN, SIP, VoIP)
- **Low cost per minute** You want to take advantage of twilio’s competitive usage pricing

### Running ZestPhone

ZestPhone is a ruby on rails application, backed by a MySql database.
It's only known to work for sure using ruby 1.9.3, but any 1.9.x ruby version is probably fine.

- You need a Twilio account of course.
- A Pusher account
- A database that is supported by rails, and that supports locking (only MySql is known to work)
- Your client-side application needs to include backbone.js

The full setup instructions are [here](SETUP.md)  (or click on the button below)

[![setup](docs/setup_button.png)](SETUP.md)

### Architecture

Zestphone is essentially an agent state coordination software in the call and conferencing domain.  While twilio handles the mechanics of connecting agents and customers over the phone, 
ZestPhone provides a layer that allows:

1. Agents to signal availablility to receive calls (presence)
2. Ability to enter / exit conferences
3. See other agent's availability statuses for transfers
4. Play greetings to inbound customers and routing functionality
5. Ability to embed a call widget into any web-based application

An architectural document is available here: [ZestPhone Architecture](docs/architecture_slide.pdf)

Here's a list of all possible states that an agent can be in (ZestPhone coordinates this): [Agent States](docs/states_diagram.png)


