Zest.Telephony.Models.Conversation = Backbone.Model.extend({
  urlRoot: Zest.Telephony.Config.CONVERSATION_PATH,

  defaults: {
    state: "disabled_by_default"
  },

  initialize: function() {
    this.enabledHoldStates    = ['in_progress', 'in_progress_two_step_transfer'];
    this.disabledHoldStates   = ['two_step_transferring', 'initiating_hold', 'agents_only'];
    this.enabledResumeStates  = ['in_progress_hold', 'in_progress_two_step_transfer_hold'];
    this.disabledResumeStates = ['initiating_resume', 'initiating_two_step_transfer_resume', 'two_step_transferring_hold'];
  },

  create: function() {
    var data = {
      loan_id: this.get("loanId"),
      from: this.get("from"),
      from_id: this.get("fromId"),
      from_type: 'csr',
      to: this.get("to"),
      to_id: this.get("toId"),
      to_type: this.get("toType"),
      owner: this.get("owner")
    };

    this.set({ state: "connecting" });
    $.ajax(this.url(), { data: data, type: 'POST' })
      .done($.proxy(this.createSuccess, this))
      .fail($.proxy(this.createFail, this));
  },

  hold: function() {
    var oldState = this.get('state');
    var newState = "initiating_hold";

    this.set({ state: newState });
    $.ajax(this.url() + "/hold", {type: 'POST'})
      .done($.proxy(this.holdResumeSuccess, this))
      .fail($.proxy(this.holdResumeFail(oldState, newState), this));
  },

  resume: function() {
    var oldState = this.get('state');
    var newState = "initiating_resume";

    this.set({ state: newState });
    $.ajax(this.url() + "/resume", {type: 'POST'})
      .done($.proxy(this.holdResumeSuccess, this))
      .fail($.proxy(this.holdResumeFail(oldState, newState), this));
  },

  holdResumeSuccess: function(data) {
    this.set(data);
  },

  holdResumeFail: function(oldState, newState) {
    return function(xhr, textStatus, errorThrown) {
      var body = JSON.parse(xhr.responseText);
      var data = {
        error: body.errors[0],
        oldState: oldState,
        newState: newState
      };

      $(document).trigger('holdResumeFail', data);
    };
  },

  uiDisableCall: function() {
    if (this.get('callingDisabled')) {
      return 'disabled';
    }

    return this._enabledForStates(['not_initiated', 'terminated']);
  },

  uiShowCall: function() {
    var displayableStates = ['not_initiated', 'connecting', 'terminated'];
    return this._shownForStates(displayableStates);
  },

  uiDisableTransfer: function() {
    var enabledStates = ['in_progress', 'in_progress_hold'];
    return this._enabledForStates(enabledStates);
  },

  uiShowTransfer: function() {
    if (this.get("isCancelable")) {
      return "hidden";
    }

    var displayableStates = [
      'in_progress',
      'one_step_transferring',
      'two_step_transferring',
      'two_step_transferring_hold',
      'initiating_two_step_transfer_resume',
      'initiating_two_step_transfer_hold',
      'in_progress_two_step_transfer_hold',
      'in_progress_two_step_transfer',
      'initiating_hold',
      'in_progress_hold',
      'initiating_resume',
      'agents_only'
    ];
    return this._shownForStates(displayableStates);
  },

  uiShowCancelTransfer: function() {
    return this.get("isCancelable") ? "" : "hidden";
  },

  uiShowResume: function() {
    var displayableStates = this.enabledResumeStates.concat(this.disabledResumeStates);
    return this._shownForStates(displayableStates);
  },

  uiDisableResume: function() {
    return this._disabledIf(this._statesIn(this.disabledResumeStates) || !this.get("owner"));
  },

  uiShowHold: function() {
    var displayableStates = this.enabledHoldStates.concat(this.disabledHoldStates);
    return this._shownForStates(displayableStates);
  },

  uiDisableHold: function() {
    return this._disabledIf(this._statesIn(this.disabledHoldStates) || !this.get("owner"));
  },

  uiShowCallSpinner: function() {
    return this._displayedForStates(['connecting']);
  },

  uiShowHoldSpinner: function() {
    return this._displayedForStates(['initiating_hold']);
  },

  uiShowResumeSpinner: function() {
    return this._displayedForStates(['initiating_resume']);
  },

  state: function() {
    return this.get("state");
  },

  createSuccess: function(data) {
    $(document).trigger("telephony:conversationCreated", data);
    this.set(data);
  },

  createFail: function(xhr, textStatus, errorThrown) {
    var body = JSON.parse(xhr.responseText);
    $(document).trigger('callFailed', body.errors[0]);
  },


  fail: function(xhr, textStatus, errorThrown) {
    if (typeof console === "object" && typeof console.log === "function") {
      console.log("Unable to complete the request: " + textStatus);
    }
  },

  isValid: function() {
    if (! this._isValidPhoneNumberFormat()) {
      return false;
    }
    if (! this._isValidCallee()) {
      return false;
    }
    return true;
  },

  _disabledIf: function(disable) {
    return disable ? 'disabled' : '';
  },

  _statesIn: function(states) {
    return _.contains(states, this.state());
  },

  _disabledForStates: function(states) {
    return this._disabledIf(this._statesIn(states));
  },

  _enabledForStates: function(states) {
    return _.contains(states, this.state()) ? '' : 'disabled';
  },

  _shownForStates: function(states) {
    return _.contains(states, this.state()) ? '' : 'hidden';
  },

  _displayedForStates: function(states) {
    return _.contains(states, this.state()) ? 'display' : '';
  },

  _isValidPhoneNumberFormat: function() {
    var phoneNumber = this._normalizePhoneNumber(this.get('to'));
    if (phoneNumber.length !== 10) {
      this.errorMessage = 'Please enter a 10-digit phone number';
      return false;
    }
    return true;
  },

  _isValidCallee: function() {
    var from = this._normalizePhoneNumber(this.get('from'));
    var to = this._normalizePhoneNumber(this.get('to'));
    if (from === to) {
      this.errorMessage = 'Please input a customer phone number';
      return false;
    }
    return true;
  },

  _normalizePhoneNumber: function(phoneNumber) {
    var number = phoneNumber || '';
    var digits = number.toString().replace(/\D/g, '');
    if (digits[0] === '1') {
      digits = digits.slice(1);
    }
    return digits;
  }
});
