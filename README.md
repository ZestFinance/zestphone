Telephony call-center functionality easily integrated into your app
=======
ZestPhone
================

## Running ZestPhone server

ZestPhone is a ruby on rails application, backed by a MySql database.
It's only known to work for sure using ruby 1.9.3, but any 1.9.x ruby version is probably fine.

- You need a Twilio account of course.
- A Pusher account
- A database that is supported by rails, and that supports locking (only MySql is known to work)
- Your application needs to include backbone.js

The complete setup guide is here: https://github.com/ZestFinance/zestphone/blob/master/SETUP.md

## Javascript events your app can respond to

All events have this basic data:

```json
  {
    event_id:
    conversation_id:
    conversation_state:
    call_id: # This will be empty for events that happen at the conversation level
    number: # The customer's number
    owner: # Is the agent receiving this event the conversation owner?
  }
```

- **telephony:Answer**:
  Fired when the agent answers his phone
- **telephony:Busy**:
  Fired to an agent whose phone was busy
- **telephony:CallFail**:
  Sent to an agent when the agent leg fails
- **telephony:CompleteHold**:
  Sent to all agents when the customer has been put on hold
- **telephony:CompleteOneStepTransfer**:
  Sent to the agent who just answered a one-step transfer
- **telephony:CompleteResume**:
  Sent to all agents when the customer is taken off of hold
- **telephony:CompleteTwoStepTransfer**:
  Sent to all agents after the 2nd agent picks up in a two-step transfer. The data sent to agent1 will include agent2's name, extension, and csr_type. The data sent to agent2 will include that data for agent1.

- **telephony:Conference**
  Sent to an agent who was just moved into a conference room. This can happen during hold or transfer actions, and is not very interesting on it's own.
- **telephony:Connect**
- **telephony:csrDidChangeStatus**
- **telephony:csrNotAvailable**
- **telephony:CustomerLeftTwoStepTransfer**
- **telephony:FailOneStepTransfer**
- **telephony:FailTwoStepTransfer**
- **telephony:InitiateOneStepTransfer**
- **telephony:InitiateTwoStepTransfer**
- **telephony:InitializeWidget**
- **telephony:LeaveTwoStepTransfer**
- **telephony:LeaveVoicemail**
- **telephony:NoAnswer**
- **telephony:QueueChange**
- **telephony:RemoveFromConference**
- **telephony:Start**
- **telephony:Terminate**
- **telephony:toggleCsrStatus**
- **telephony:WidgetReady**
- **telephony:conversationCreated**
- **transferInitiated**

## Javascript events you can trigger from your app
  - **telephony:ClickToCall**: Sample usage: ```javascript
      $(this).trigger("telephony:ClickToCall", to: $(event.currentTarget).text());
  ```
