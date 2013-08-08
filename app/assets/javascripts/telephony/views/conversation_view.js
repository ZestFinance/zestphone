Zest.Telephony.Views.ConversationView = Backbone.View.extend({
  className: 'conversation-wrapper',

  events: {
    'click button.initiate-conversation' : 'createConversation',
    'click button.cancel-transfer': 'cancelTransfer',
    'click button.initiate-hold': 'hold',
    'click button.resume': 'resume',
    'click button.show-agents': 'openTransferView'
  },

  template: JST["templates/telephony/conversation_view"],

  initialize: function() {
    this.setupNewConversation();

    $(document)
      .bind("transferInitiated", $.proxy(this.cancelTransfer, this))
      .bind('callFailed', $.proxy(this.displayCallFailedMessage, this))
      .bind('holdResumeFail', $.proxy(this.displayHoldResumeFailedMessage, this))
      .bind('transferFailed', $.proxy(this.displayTransferFailedMessage, this))
      .bind("telephony:InitializeWidget", $.proxy(this.onInitializeWidget, this))
      .bind("telephony:ClickToCall", $.proxy(this.onClickToCall, this))
      .bind("telephony:Connect", $.proxy(this.onConnect, this))
      .bind("telephony:Start", $.proxy(this.onStart, this))
      .bind("telephony:Busy telephony:NoAnswer telephony:CallFail telephony:Terminate",
            $.proxy(this.onCallEnded, this))
      .bind("telephony:InitiateOneStepTransfer", $.proxy(this.onInitiateOneStepTransfer, this))
      .bind("telephony:CompleteOneStepTransfer", $.proxy(this.onCompleteOneStepTransfer, this))
      .bind("telephony:FailOneStepTransfer", $.proxy(this.onFailOneStepTransfer, this))
      .bind("telephony:InitiateTwoStepTransfer", $.proxy(this.onInitiateTwoStepTransfer, this))
      .bind("telephony:CompleteTwoStepTransfer", $.proxy(this.onCompleteTwoStepTransfer, this))
      .bind("telephony:CustomerLeftTwoStepTransfer", $.proxy(this.onCustomerLeftTwoStepTransfer, this))
      .bind("telephony:LeaveTwoStepTransfer", $.proxy(this.onLeaveTwoStepTransfer, this))
      .bind("telephony:CompleteHold", $.proxy(this.onCompleteHold, this))
      .bind("telephony:CompleteResume", $.proxy(this.onCompleteResume, this))
      .bind("telephony:FailTwoStepTransfer", $.proxy(this.onFailTwoStepTransfer, this));
  },

  hold: function() {
    this.conversation.hold();
  },

  resume: function() {
    this.conversation.resume();
  },

  displayCallFailedMessage: function(event, data) {
    this.friendlyMessage = data;
    this.conversation.set({state: "not_initiated"});
  },

  displayTransferFailedMessage: function(event, data) {
    this.friendlyMessage = data;
    this.conversation.set({state: "in_progress"});
  },

  displayHoldResumeFailedMessage: function(event, data) {
    this.friendlyMessage = data.error;

    if (this.conversation.get('state') === data.newState) {
      this.conversation.set({state: data.oldState});
    } else {
      this.render();
    }
  },

  onInitializeWidget: function() {
    this.friendlyMessage = "";
    this.conversation.set({state: "not_initiated"});
  },

  disableCallControl: function(opts) {
    this.conversation.set({callingDisabled: opts.callingDisabled});
    this.render();
  },

  setupNewConversation: function() {
    this.conversation = new Zest.Telephony.Models.Conversation({
      loanId: this.options.loanId,
      from: this.options.agentNumber,
      fromId: this.options.fromId
    });
    this.conversation
      .bind("change:state", $.proxy(this.render, this));
  },

  showCancelTransfer: function() {
    this.conversation.set({isCancelable: true});
  },

  cancelTransfer: function() {
    $(this.el).animate({height: '50px'});

    this.conversation.set({isCancelable: false});
    this.transferView = null;
    this.render();
  },

  createConversation: function(event) {
    this.setupNewConversation();

    event.preventDefault();
    var number = this.$('input[name=number]').val();
    this.conversation.set({
      to: number,
      state: "not_initiated"
    });
    if (this.conversation.isValid()) {
      this.friendlyMessage = "";
      this.conversation.create();
    } else {
      this.friendlyMessage = this.conversation.errorMessage;
      this.render();
    }
  },

  onClickToCall: function(event, data) {
    this.conversation.set({
      to: data.to,
      toId: data.to_id,
      toType: data.to_type
    });
    this.friendlyMessage = data.callee_name || '';
    this.render();
  },

  onConnect: function (event, data) {
    this.friendlyMessage = 'Ringing';
    this.setConversationData(data);
    this.render();
  },

  setConversationData: function(data) {
    this.conversation.set({
      to: data.number,
      state: data.conversation_state,
      id: data.conversation_id,
      owner: data.owner
    });
  },

  openTransferView: function(event) {
    event.preventDefault();
    this.showAgents();
  },

  showAgents: function() {
    this.showCancelTransfer();
    $(this.el).animate({height: '100px'});

    var $transferWrapper = this.$('.transfer-wrapper');

    var conversationId = this.conversation.get("id");

    if(this.transferView) {
      this.transferView.el = $transferWrapper;
      this.transferView.conversationId = conversationId;
      this.transferView.rebindEvents();
    } else {
      this.transferView = new Zest.Telephony.Views.TransferView({
        el: $transferWrapper,
        conversationId: conversationId
      });
    }
    this.transferView.render();
  },

  onStart: function(event, data) {
    this.friendlyMessage = 'Connected';
    this.setConversationData(data);
    this.render();
  },

  onCallEnded: function(event, data) {
    this.friendlyMessage = 'Call Ended';
    this.conversation.set({
      to: '',
      state: 'terminated',
      id: data.conversation_id,
      owner: data.owner,
      isCancelable: false
    });
    this.render();
    $(this.el).animate({height: '50px'});
    this.$('.friendly-message').animate({ opacity: 0 },
                                        this.friendlyMessageFadeOutTime || 5000);
  },

  onInitiateOneStepTransfer: function(event, data) {
    if (data.transferrer) {
      return;
    }
    this.friendlyMessage = '1-step transfer from ' + data.agent_type + " - " +
      data.agent_name + ' x' + data.agent_ext;

    this.setConversationData(data);
    this.render();
  },

  onCompleteOneStepTransfer: function(event, data) {
    this.friendlyMessage = 'Connected';
    this.setConversationData(data);
    this.render();
  },

  onFailOneStepTransfer: function(event, data) {
    if (data.transferrer) {
      this.conversation.set({
        state: 'terminated'
      });
      return;
    }
    this.friendlyMessage = 'Missed 1-step transfer from ' + data.agent_type + " - " +
      data.agent_name + ' x' + data.agent_ext;

    this.conversation.set({
      id: data.conversation_id,
      state: 'terminated',
      to: data.number,
      owner: data.owner
    });
    this.render();
  },

  onInitiateTwoStepTransfer: function(event, data) {
    if (data.transferrer) {
      this.friendlyMessage = 'Ringing ' + data.agent_type + " - " +
        data.agent_name + ' x' + data.agent_ext;
    } else {
      this.friendlyMessage = '2-step transfer from ' + data.agent_type + " - " +
        data.agent_name + ' x' + data.agent_ext;
    }

    this.conversation.set({
      disabledTransfer: true,
      state: data.conversation_state,
      to: data.number,
      owner: data.owner
    });
    this.render();
  },

  onFailTwoStepTransfer: function(event, data) {
    if (data.transferrer) {
      this.friendlyMessage = 'No Answer - ' + data.agent_name + " x" +
        data.agent_ext;
      this.nextFriendlyMessage = "Connected";

      this.setConversationData(data);
      this.render();
      this.$('.friendly-message').animate({ opacity: 0 },
          { duration: this.friendlyMessageFadeOutTime || 5000,
            complete: $.proxy(this.afterFriendlyMessageDecay, this)
          });
    } else {
      this.friendlyMessage = 'Missed 2-step transfer from ' + data.agent_type + " - " +
        data.agent_name + ' x' + data.agent_ext;

      this.conversation.set({
        to: data.number,
        state: 'terminated',
        id: data.conversation_id,
        owner: data.owner
      });
      this.render();
    }
  },

  afterFriendlyMessageDecay: function() {
    if (this.nextFriendlyMessage) {
      this.friendlyMessage = this.nextFriendlyMessage;
      this.nextFriendlyMessage = null;
      this.render();
    }
  },

  onCompleteTwoStepTransfer: function(event, data) {
    this.friendlyMessage = 'Connected to ' + data.agent_type + " - " +
      data.agent_name + ' x' + data.agent_ext;
    this.setConversationData(data);
    this.render();
  },

  onCustomerLeftTwoStepTransfer: function(event, data) {
    this.friendlyMessage = 'Connected to ' + data.agent_type + " - " +
      data.agent_name + ' x' + data.agent_ext;
    this.setConversationData(data);
    this.render();
  },

  onLeaveTwoStepTransfer: function(event, data) {
    this.friendlyMessage = 'Connected';
    this.setConversationData(data);
    this.render();
  },

  onCompleteHold: function(event, data) {
    this.setConversationData(data);
  },

  onCompleteResume: function(event, data) {
    this.setConversationData(data);
  },

  render: function () {
    var html = this.template({
      conversation: this.conversation,
      friendlyMessage: this.friendlyMessage
    });
    $(this.el).html(html);

    this.buttonsView = new Zest.Telephony.Views.ConversationButtonsView({
      conversation: this.conversation
    });
    this.$('form').append(this.buttonsView.render().el);
    if (this.conversation.get('isCancelable')) {
      this.showAgents();
    }
    return this;
  }
});
