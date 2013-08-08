Zest.Telephony.Views.WidgetView = Backbone.View.extend({
  className: 'telephony-widget-container',

  disableCallControl: function(opts) {
    this.conversationView.disableCallControl(opts);
  },

  loadTwilioClient: function() {
    this.twilioClientView = new Zest.Telephony.Views.TwilioClientView({
      csrId: this.options.csrId,
      agent: this.statusView.agent
    });
    $(this.el).append(this.twilioClientView.render().el);
  },

  logFail: function(xhr, textStatus, errorThrown) {
    if (typeof console === "object" && typeof console.log === "function") {
      console.log('Failed to load Twilio Client');
    }
  },

  render: function() {
    $("<link/>", {
       rel: "stylesheet",
       type: "text/css",
       href: Zest.Telephony.Config.STYLESHEET_PATH
    }).appendTo("head");

    this.callQueueView = new Zest.Telephony.Views.CallQueueView();

    $(this.el).append(this.callQueueView.render().el);

    this.statusView = new Zest.Telephony.Views.StatusView({
      csrId: this.options.csrId
    });

    $(this.el).append(this.statusView.render().el);

    this.conversationView = new Zest.Telephony.Views.ConversationView({
      loanId: this.options.loanId,
      agentNumber: this.options.agentNumber,
      fromId: this.options.csrId
    });

    $(this.el).append(this.conversationView.render().el);

    if (Zest.Telephony.Config.TWILIO_CLIENT_ENABLED) {
      $.getScript(Zest.Telephony.Config.TWILIO_CLIENT_URL)
        .done($.proxy(this.loadTwilioClient, this))
        .fail($.proxy(this.logFail, this));
    }

    return this;
  }
});
