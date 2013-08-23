## Zestphone setup

### We have two goals:
1) To be able to run the tests (bundle exec rake)
2) To be able to make a phone call

We'll start with running the tests, because that gets you much of the way there.

### Prerequisites:
1) A twilio account. (twilio.com)
2) A pusher account. (pusher.com)

### Configure your development server
- git clone git@github.com:ZestFinance/zestphone.git
- cd zestphone/
bundle install
be rake app:db:create:all
be rake app:db:migrate
be rake app:db:test:prepare
cp spec/dummy/config/twilio.yml.example spec/dummy/config/twilio.yml
cp spec/dummy/config/pusher.yml.example spec/dummy/config/pusher.yml
be rake

### Allow Twilio to connect to you
The trickiest thing about twilio development is that twilio has to call your server, which means your server has to be accessible from the outside world. Basically what happens is during the life of a call twilio fires events to a url that you specify, so that your app knows when a call is answered, hung up, etc.

There are a few different ways to make this happen, and none of them are very user-friendly.
1) Be on a box that allows your rails server (port 3000 by default) to be accessible from the internet. This is the easiest.
2) Open an ssh tunnel to a machine that is externally available and port forward to your local machine. A sample command to do this: ssh -N -R 8000:0:3000 example.com. This forwards port 8000 on example.com to port 3000 on your local machine.
3) Use localtunnel. Instructions here: http://www.twilio.com/engineering/2011/06/06/making-a-local-web-server-public-with-localtunnel
4) Use ngrok https://ngrok.com/


Whatever your external facing domain and port are, make a note and we’ll refer to it as EXTERNAL_HOST. In the example command in #2 above, this would be http://example.com:8000

### Setup Twilio Locally
You will need to obtain a phone number from your Twilio account to handle inbound calls. Log into your Twilio account, and click on Numbers from the header (https://www.twilio.com/user/account/phone-numbers/incoming).

Create a number or configure an existing one. Edit the number and change the “Voice Request URL” to EXTERNAL_HOST/providers/twilio/inbound_calls. For example, http://example.com:8000/zestphone/providers/twilio/inbound_calls. Make sure this is configured as a POST request.

#### Edit your Config Files
vim spec/dummy/config/twilio.yml
# Follow the instructions in the twilio.yml file.
Make sure callback_root: looks something like the following:
  callback_root: http://example.com:8000/zestphone

Add a Pusher webhook for your service ( You can use same webhook as the EXTERNAL_HOST )
https://app.pusherapp.com/apps/your_app_id/web_hooks
Make sure Presence is selected

vim spec/dummy/config/pusher.yml
# Follow the instructions in the pusher.yml file.
Pusher >> Choose App > Your App Name > API Access
https://app.pusherapp.com/apps/your_app_id/api_access

cd spec/dummy
bundle exec rails server

In theory, everything works now. You need two phones to verify that all is well. Try it!

Navigate to:
http://localhost:3000/?agent-number=<your_cell_number>

You should now be able to type <your_friends_cell_number> in the textbox and hit “call”.
Several things should happen if all is working right:
Your status should change from “available” to “on a call”
<your_cell_number> should ring.
<your_friends_cell_number> should ring after you answer <your_cell_number>.
You should be on a call, and you should be able to hold/transfer/hangup/whatever the call through the UI.

