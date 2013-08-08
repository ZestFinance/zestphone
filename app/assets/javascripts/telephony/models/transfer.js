Zest.Telephony.Models.Transfer = Backbone.Model.extend({
  url: function() {
    return Zest.Telephony.Config.BASE_PATH + "/conversations/" + this.get("conversationId") +  "/transfers";
  },

  defaults: {
    "transferType": "two_step"
  },

  toJSON: function() {
    var selectedAgent = this.get("selectedAgent");
    return {
      transfer_id: selectedAgent.get("csr_id"),
      transfer_type: this.get("transferType")
    }
  },

  selectedAgentDisplayText: function() {
    var selectedAgent = this.get("selectedAgent");
    return selectedAgent ? selectedAgent.displayText() : "";
  },

  uiShowClearSelectedAgent: function() {
    return this.get("selectedAgent") ? "" : "hidden";
  },

  uiDisabledFilter: function() {
    return this.get("selectedAgent") ? "disabled" : "";
  },

  uiShowAgentsList: function() {
    return this.get("selectedAgent") ? "hidden" : "";
  },

  uiDisabledTwoStep: function() {
    var agent = this.get("selectedAgent");
    if (agent && agent.available()) {
      return "";
    } else {
      return "disabled";
    }
  },

  uiCheckedOneStep: function() {
    var agent = this.get("selectedAgent");
    if (agent && agent.available()) {
      return "";
    } else {
      return "checked";
    }
  },

  uiCheckedTwoStep: function() {
    var agent = this.get("selectedAgent");
    if (agent && agent.available()) {
      return "checked";
    } else {
      return "";
    }
  },

  uiShowTransferControl: function() {
    return this.get("selectedAgent") ? "" : "hidden";
  }
});
