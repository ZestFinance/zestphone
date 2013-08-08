Zest.Telephony.Views.TwilioClientView = Backbone.View.extend({
  className: 'twilio-client-wrapper',

  events: {
    'click button.answer': 'deviceAnswer',
    'click button.hangup': 'deviceHangup'
  },

  template: JST["templates/telephony/twilio_client_view"],

  initialize: function(options) {
    this.agent = options.agent;

    this.device = new Zest.Telephony.Models.Device();
    this.device.bind("change:state", $.proxy(this.render, this));

    $(document)
      .bind("telephony:Answer", $.proxy(this.onAnswer, this))
      .bind("telephony:Start", $.proxy(this.onAnswer, this))
      .bind("telephony:Conference", $.proxy(this.onAnswer, this))
      .bind("telephony:CompleteOneStepTransfer", $.proxy(this.onAnswer, this))
      .bind("telephony:CompleteTwoStepTransfer", $.proxy(this.onAnswer, this))
      .bind("telephony:Busy telephony:NoAnswer telephony:CallFail telephony:Terminate",
            $.proxy(this.onCallEnded, this));

    this.tokenPath = Zest.Telephony.Config.TWILIO_CLIENT_TOKEN_PATH;
    var data = { csr_id: options.csrId };
    $.ajax(this.tokenPath, { type: 'GET', data: data })
      .done($.proxy(this.loadToken, this))
      .fail($.proxy(this.logFail, this));
  },

  loadToken: function(data) {
    var token = data.token;
    this.setupTwilioClient(token);
  },

  logFail: function(xhr, textStatus, errorThrown) {
    if (typeof console === "object" && typeof console.log === "function") {
      console.log('Failed to load capability token');
    }
  },

  setupTwilioClient: function(token) {
    Twilio.Device.setup(token, {debug: false});
    Twilio.Device.ready($.proxy(this.deviceReady, this));
    Twilio.Device.error($.proxy(this.deviceError, this));
    Twilio.Device.incoming($.proxy(this.deviceIncoming, this));
    Twilio.Device.connect($.proxy(this.deviceConnect, this));
    Twilio.Device.disconnect($.proxy(this.deviceDisconnect, this));
  },

  deviceReady: function(dev) {
    this.device.set({ state: 'ready' });
  },

  deviceError: function(err) {
    this.device.set({ state: 'error' });
  },

  deviceIncoming: function(conn) {
    this.connection = conn;
    this.device.set({ state: 'incoming' });
  },

  deviceConnect: function(conn) {
    this.device.set({ state: 'connect' });
  },

  deviceDisconnect: function(conn) {
    this.device.set({ state: 'disconnect' });
  },

  deviceAnswer: function() {
    this.connection.accept();
    this.disallowBrowserReload();

    this.device.set({ state: 'answering' });
  },

  deviceHangup: function() {
    Twilio.Device.disconnectAll();
    this.allowBrowserReload();

    this.device.set({ state: 'ready' });
  },

  onAnswer: function(event, data) {
    this.device.set({ state: 'connect' });
    this.render();
  },

  onCallEnded: function(event, data) {
    this.device.set({ state: 'ready' });
    this.render();
  },

  disallowBrowserReload: function() {
    this.currentBeforeUnload = window.onbeforeunload;
    var that = this;
    $(window).bind('beforeunload', function() {
      if (that.agent.onACall()) {
        return 'You are ON A CALL. If you leave this page your call will be terminated.';
      }
    });
  },

  allowBrowserReload: function() {
    $(window).unbind('beforeunload');
    window.onbeforeunload = this.currentBeforeUnload;
  },

  render: function() {
    $(this.el).html(this.template({ device: this.device }));
    return this;
  }
});
