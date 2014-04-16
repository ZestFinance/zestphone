## Setup Instructions

Zestphone is a rails engine that can be integrated into other apps as part of a call / agent coordination solution.  
It also comes with a "dummy" app that allows you to start up a self-contained, live call coordination solution.

By the end of these step-by-step setup instructions, you should be able to:

1. Run the tests successfully (bundle exec rake)
2. Make and receive live phone calls on the system


### Contents

- [External Services](#external-services)
- [Configure Project and Tests](#configure-project-and-tests)
- [Tunneling Solutions](#tunneling-solutions)
- [Twilio-App Interoperability Setup](#twilio-app-interoperability-setup)
- [Pusher-App Interoperability Setup](#pusher-app-interoperability-setup)
- [Server Startup / Testing](#server-startup--testing)


### External Services

Zestphone is tightly integrated with the following two (paid) services.  Set up accounts on these two services and then we'll continue connecting your app to these services.

1. A twilio account (twilio.com) - for making, receiving, and coordinating calls
2. A pusher account (pusher.com) - for pushing call / conversation / agent statuses from the zestphone server-side to agent browser call widgets globally


### Configure Project and Tests

By the end of this section, you should be able to run through setup and project tests successfully.
We'll dive into the configuration files in later sections of the setup tutorial

```
# Clone the repository, set up gem dependencies
git clone git@github.com:ZestFinance/zestphone.git
cd zestphone/
bundle install

# Create configuration files
cp spec/dummy/config/twilio.yml.example spec/dummy/config/twilio.yml
cp spec/dummy/config/pusher.yml.example spec/dummy/config/pusher.yml
cp spec/dummy/config/call_centers.yml.example spec/dummy/config/call_centers.yml

# Database setup and migrations
bundle exec rake app:db:create:all
bundle exec rake app:db:migrate
bundle exec rake app:db:test:prepare

# Run tests
bundle exec rake
```


### Tunneling Solutions

The trickiest thing about development with zestphone is that both external services operate on a callback model, which requires your development runtime to be accessible from the outside world. 
There are several different ways to make this happen, which are listed below.  We recommend that you utilize (4) - ngrok, if possible.  However, all tunneling options are listed below so you can choose what works best for you

1. Be on a box that allows your rails server (port 3000 by default) to be accessible from the internet. This is the easiest.
2. Open an ssh tunnel to a machine that is externally available and port forward to your local machine. A sample command to do this: `ssh -N -R 8000:0:3000 example.com`. This forwards port 8000 on example.com to port 3000 on your local machine.  The publicly accessible url will be http://example.com:8000
3. Use localtunnel: [instructions here](http://www.twilio.com/engineering/2011/06/06/making-a-local-web-server-public-with-localtunnel)
4. Use ngrok: [ngrok.com](http://ngrok.com).  You'll need to download a binary and set up an account on ngrok.  Once you set up an account, a publicly-accessible URL is assigned to you, which will port-forward to your local development machine.  Note the url.

Whatever your external facing domain and port are (for ngrok it'll be given to you once you set up an account), make a note of it and we’ll refer to it as EXTERNAL_HOST in the setup instructions below. 
In the example command in #2 above, this would be http://example.com:8000


### Twilio-App Interoperability Setup

#### Twilio Number / Callback (on twilio.com)

You will need to obtain a phone number from your Twilio account to handle inbound calls, and also wire the number's callback url to your local development environment

1. Log into your Twilio account and click on "Numbers" in the header navigation.
2. Create a number or configure an existing one. 
3. Edit the number's callback settings by changing “Voice Request URL” to: EXTERNAL_HOST/providers/twilio/inbound_calls. 
<i>For example, http://example.com:8000/zestphone/providers/twilio/inbound_calls. </i>
4. Make sure that this is configured as a POST request

#### Twilio Config File (locally)

The twilio config file allows your app to be wired up to your twilio account number that you've provisioned above.
Open the file:  `spec/dummy/config/twilio.yml` for editing.  This is the same file that was copied in the app setup instructions.
You'll need to edit the following properties: (there are also additional instructions in the file)

1. outbound_caller_id: instructions in the twilio.yml file
2. callback_root: instructions in the twilio.yml file.  This property ensures that our requests/responses to twilio will contain the proper callback url back to your development environment.   The url should look like the following: `EXTERNAL_HOST/zestphone` (note the /zestphone URI)
3. account_sid: user account sid and auth tokens
4. auth_token: user account sid and auth tokens


### Pusher-App Interoperability Setup

Pusher makes a call back to zestphone when an agent loads the widget and becomes available.  This is known both in pusher and our system as a "presence" event".
In addition, we rely upon pusher to "push" zestphone's call states to each agent online.  Since this communication is bi-directional, we'll need to edit settings
on pusher and in zestphone

#### Pusher Callback (on pusher.com)

1. Set up an app on pusher (via pusher.com).  This will be your app's primary communications bus.
2. Create a webhook on your pusher app to your service: this is the callback url, and is the URL that pusher will call for presence events.  The url will be: `EXTERNAL_HOST/zestphone/signals/agents/presences`.  Note the "zestphone/*" URI after the "EXTERNAL_HOST".  Ensure that the "Presence" event is selected.

#### Pusher Config File (locally)

Open the file `spec/dummy/config/pusher.yml`.  Edit the following properties (below).  
All of these properties are available after you click on "App Keys".

1. app_id: this is the app-id property in the API credentials
2. app_key: in section "Access Tokens" in API credentials
3. secret: (same as above)


### Server Startup / Testing

```
cd spec/dummy
bundle exec rails server
```

#### Test Scenario

You will need two phones to perform the live test.  The test we'll be performing is to simulate an agent becoming available and making an outbound call to a customer.
Twilio dials both you as well as your counterparty, and then puts the two of you into a conference call. 

1. Navigate to: `http://localhost:3000/?agent-number=<your_phone_1>`
2. Click on the "available" button, it should switch to "unavailable" and also disable the call button.  Make yourself available again.
3. Enter another phone number (yours or your friend's) into the textbox and click "call".
4. Your phone will ring, after which your friend's phone will ring.  Pick up.
4. Both calls should now be connected, and you should be able to speak to each other.
5. You should see your status change from "available" to "on a call"
6. You can not play w/ various state options available on the call widget, including hold/transfer/hangup, etc.

To validate that the pusher is receiving and pushing events correctly, log into your account on pusher.com, click on the app channel that you've created, and 
click on the link "Debug Console".   As you interact w/ the telephony app and various actions are taken, you should see messages being pushed
to your pusher channel.  These events in turn get pushed out to your browser.   In an multi-agent setting, all events will get pushed out
to all agent browsers - this is how zestphone is able to coordinate the entire agent workforce





