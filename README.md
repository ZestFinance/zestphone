# ZestPhone [![Build Status](https://travis-ci.org/ZestFinance/zestphone.svg?branch=master)](https://travis-ci.org/ZestFinance/zestphone) [![Code Climate](https://codeclimate.com/github/ZestFinance/zestphone.png)](https://codeclimate.com/github/ZestFinance/zestphone)
Telephony call center software

## Who we are
We are Zestfinance (zestfinance.com) a financial services company that helps lenders with underwriting and loan servicing.  In addition to building cutting-edge underwriting algorithms, we’ve also built a host of home-grown CRM tools and loan servicing products for our lending partners.  We recently added call-center style phone controls into our existing CRM by leveraging Twilio’s cloud-based communication technology, which we call ZestPhone.

## What is ZestPhone?
ZestPhone is a drop-in phone widget that can be simply added to any web application to give you full call center functionality.

## Features:
- Inbound and outbound calling
- Call outbound to anywhere in the world*
- Set up your existing business phone number with Twilio or purchase one from Twilio to get started
- Have multiple business phone numbers in use for marketing attribution
- Cold and warm transfer
- Allow your agents transfer calls to each other either directly or with introduction
- Put a call on hold / resume a call
- Agent status
- Ability to respond to telephony events in your application
- Uses existing agent names/numbers/ids
- Embeds into your existing javascript-enabled application
- PSTN or VoIP (i.e. use a regular phone, SIP, or twilio client)
- Call recording
- All calls are recorded while the customer is on the line with an agent and are stored by Twilio (storage rates apply)
- Voicemail
- Customers can be transferred to a specific agent’s voicemail if the agent is busy with another customer or offline

## Why use ZestPhone / Am I (or my company) a good candidate?
- **Quick integration** You want to quickly and easily add phone capabilities to your application
- **1:1 Customer Service Experience** You want to empower your call center agents to provide 1:1 support to customers with easy-to-use transfer and voicemail capabilities
- **Use any type of phone** You have call centers with different phone setups and want software to support them all (PSTN, SIP, VoIP)
- **Low cost per minute** You want to take advantage of twilio’s competitive usage pricing

## Running ZestPhone server

ZestPhone is a ruby on rails application, backed by a MySql database.
It's only known to work for sure using ruby 1.9.3, but any 1.9.x ruby version is probably fine.

- You need a Twilio account of course.
- A Pusher account
- A database that is supported by rails, and that supports locking (only MySql is known to work)
- Your application needs to include backbone.js

The complete setup guide is here: https://github.com/ZestFinance/zestphone/blob/master/SETUP.md
