Zest.Telephony.Models.Agent = Backbone.Model.extend({
  urlRoot: Zest.Telephony.Config.AGENT_PATH,

  defaults: {
    "status": "loading...",
    "in_transition": false
  },

  url: function() {
    return this.urlRoot + "/" + this.get("csr_id");
  },

  statusUrl: function() {
    return this.url() + "/status"
  },

  status: function() {
    return this.get('status');
  },

  displayText: function() {
    return this.get("csr_type") + " " + this.get("name") + " x" + this.get("phone_ext");
  },

  toggleAvailable: function() {
    this.updateStatus("toggle_available");
  },

  updateStatus: function(eventName) {
    var data = {};
    data["event"] = eventName || "not_available";

    this.set({in_transition: true});
    $.ajax(this.statusUrl(), {data: data, type: 'PUT'})
      .done($.proxy(this.done, this))
      .fail($.proxy(this.fail, this))
      .always($.proxy(this.always, this));
  },

  isValid: function(opts) {
    opts = opts || {}
    $.ajax(this.url(), {data: this.toJSON(), type: 'PUT'})
      .done(opts['done_callback'])
      .fail(opts['fail_callback']);
  },

  disabled: function() {
    if (this.onACall() || this.offline() || this.inTransition()) {
      return "disabled";
    }
    return "";
  },

  display: function() {
    if (this.inTransition() || this.loading()) {
      return "display";
    }
    return "";
  },

  inTransition: function() {
    return this.get("in_transition");
  },

  onACall: function() {
    return this.get("status") === "on_a_call";
  },

  offline: function() {
    return this.get("status") === "offline";
  },

  available: function() {
    return this.get("status") === "available";
  },

  notAvailable: function() {
    return this.get("status") === "not_available";
  },

  loading: function() {
    return this.get("status") === "loading...";
  },

  humanizedStatus: function() {
    var humanizedStatus = this.get('status').replace(/_/g, ' ');
    return humanizedStatus.substr(0,1).toUpperCase() + humanizedStatus.substr(1);
  },

  done: function(data) {
    this.set(data, {silent: true});
  },

  always: function() {
    this.set({in_transition: false});
  },

  fail: function(xhr, textStatus, errorThrown) {
    if (typeof console === "object" && typeof console.log === "function") {
      console.log("Unable to update the status: " + textStatus);
    }
  }
});
