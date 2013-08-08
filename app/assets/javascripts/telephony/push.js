Zest.Telephony.Push = (function($) {
  return {
    init: function(socket) {
      this.lastCallEventId = 0;
      this.lastQueueChangeEventId = 0;
      this.lastStatusChangeEventAt = 0;
      var $widgetWrapper = $("#telephony-widget");
      this.socket = socket ||
        new Pusher(Zest.Telephony.Config.PUSHER_APP_KEY,
          { auth: {
              params: {
                csr_id: $widgetWrapper.data('csr_id'),
                csr_default_status: $widgetWrapper.data('agent_default_status')
              }
            }
          });
      var csrId = $widgetWrapper.data('csr_id');
      var presenceChannel = this.socket.subscribe('presence-' + csrId);

      var allCsrsChannel = this.socket.subscribe('csrs');
      allCsrsChannel.bind('QueueChange', this._emitQueueChangeEvent('telephony:QueueChange'));

      var csrChannel = this.socket.subscribe('csrs-' + csrId);
      csrChannel.bind('statusChange', this._emitStatusEvent('telephony:csrDidChangeStatus'));
      csrChannel.bind('InitializeWidget', this._emitEvent('telephony:InitializeWidget'));
      csrChannel.bind('Connect', this._emitCallEvent('telephony:Connect'));
      csrChannel.bind('Answer', this._emitCallEvent('telephony:Answer'));
      csrChannel.bind('Conference', this._emitCallEvent('telephony:Conference'));
      csrChannel.bind('Start', this._emitCallEvent('telephony:Start'));
      csrChannel.bind('Busy', this._emitCallEvent('telephony:Busy'));
      csrChannel.bind('NoAnswer', this._emitCallEvent('telephony:NoAnswer'));
      csrChannel.bind('CallFail', this._emitCallEvent('telephony:CallFail'));
      csrChannel.bind('Terminate', this._emitCallEvent('telephony:Terminate'));
      csrChannel.bind('InitiateTwoStepTransfer', this._emitCallEvent('telephony:InitiateTwoStepTransfer'));
      csrChannel.bind('FailTwoStepTransfer', this._emitCallEvent('telephony:FailTwoStepTransfer'));
      csrChannel.bind('CompleteTwoStepTransfer', this._emitCallEvent('telephony:CompleteTwoStepTransfer'));
      csrChannel.bind('CustomerLeftTwoStepTransfer', this._emitCallEvent('telephony:CustomerLeftTwoStepTransfer'));
      csrChannel.bind('LeaveTwoStepTransfer', this._emitCallEvent('telephony:LeaveTwoStepTransfer'));
      csrChannel.bind('InitiateOneStepTransfer', this._emitCallEvent('telephony:InitiateOneStepTransfer'));
      csrChannel.bind('CompleteOneStepTransfer', this._emitCallEvent('telephony:CompleteOneStepTransfer'));
      csrChannel.bind('CompleteHold', this._emitCallEvent('telephony:CompleteHold'));
      csrChannel.bind('CompleteResume', this._emitCallEvent('telephony:CompleteResume'));
      csrChannel.bind('FailOneStepTransfer', this._emitCallEvent('telephony:FailOneStepTransfer'));
      csrChannel.bind('LeaveVoicemail', this._emitCallEvent('telephony:LeaveVoicemail'));
      csrChannel.bind('QueueChange', this._emitQueueChangeEvent('telephony:QueueChange'));
    },
    _emitEvent: function (name) {
      return function(data) {
        $(document).trigger(name, data);
      };
    },
    _emitQueueChangeEvent: function (name) {
      var that = this;
      return function(data) {
        if (that.lastQueueChangeEventId < data.event_id) {
          $(document).trigger(name, data);
          that.lastQueueChangeEventId = data.event_id;
        }
      };
    },
    _emitStatusEvent: function (name) {
      var that = this;
      return function(data) {
        if (that.lastStatusChangeEventAt < data.timestamp) {
          $(document).trigger(name, data);
          that.lastStatusChangeEventAt = data.timestamp;
        }
      };
    },
    _emitCallEvent: function (name) {
      var that = this;
      return function(data) {
        if (that.lastCallEventId < data.event_id) {
          $(document).trigger(name, data);
          that.lastCallEventId = data.event_id;
        }
      };
    }
  };
})(jQuery);
