Zest.Telephony.Models.Device = Backbone.Model.extend({

  defaults: {
    state: "disabled_by_default"
  },

  state: function() {
    return this.get("state");
  },

  uiShowAnswerButton: function() {
    var displayableStates = ['ready', 'error', 'disconnect', 'incoming', 'answering'];
    return _.contains(displayableStates, this.state()) ? '' : 'hidden';
  },

  uiDisableAnswerButton: function() {
    var enabledStates = ['incoming'];
    return _.contains(enabledStates, this.state()) ? '' : 'disabled';
  },

  uiShowHangupButton: function() {
    var displayableStates = ['connect'];
    return _.contains(displayableStates, this.state()) ? '' : 'hidden';
  },

  uiDisableHangupButton: function() {
    var enabledStates = ['connect'];
    return _.contains(enabledStates, this.state()) ? '' : 'disabled';
  }
});
