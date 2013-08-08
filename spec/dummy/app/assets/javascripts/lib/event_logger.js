(function($, _) {
  var events = [
    'telephony:Answer',
    'telephony:Busy',
    'telephony:CallFail',
    'telephony:ClickToCall',
    'telephony:CompleteHold',
    'telephony:CompleteOneStepTransfer',
    'telephony:CompleteResume',
    'telephony:CompleteTwoStepTransfer',
    'telephony:Conference',
    'telephony:Connect',
    'telephony:csrDidChangeStatus',
    'telephony:csrNotAvailable',
    'telephony:CustomerLeftTwoStepTransfer',
    'telephony:FailOneStepTransfer',
    'telephony:FailTwoStepTransfer',
    'telephony:InitiateOneStepTransfer',
    'telephony:InitiateTwoStepTransfer',
    'telephony:InitializeWidget',
    'telephony:LeaveTwoStepTransfer',
    'telephony:LeaveVoicemail',
    'telephony:NoAnswer',
    'telephony:QueueChange',
    'telephony:RemoveFromConference',
    'telephony:Start',
    'telephony:Terminate',
    'telephony:toggleCsrStatus',
    'telephony:WidgetReady',
    'telephony:conversationCreated',
    'transferInitiated'
  ];

  _.each(events, function(event_name) {
    $(document)
      .bind(event_name, logEvent);
  });

  function logEvent(event, data) {
    if (!data) {
      data = {};

      if (typeof console === "object" && typeof console.log === "function") {
        console.log('data was undefined for ' + event.type);
      }
    }

    var event_data_text = syntaxHighlight(data);
    var text = event.type + " - data: " + event_data_text;
    var $pre = $('<pre>').html(text);
    var $item = $('<li>').append($pre);
    $('.events ul').append($item);
  }

  function syntaxHighlight(json) {
    if (typeof json != 'string') {
      json = JSON.stringify(json, undefined, 2);
    }
    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
      var cls = 'number';
      if (/^"/.test(match)) {
        if (/:$/.test(match)) {
          cls = 'key';
        } else {
          cls = 'string';
        }
      } else if (/true|false/.test(match)) {
        cls = 'boolean';
      } else if (/null/.test(match)) {
        cls = 'null';
      }
      return '<span class="' + cls + '">' + match + '</span>';
    });
  }
})(jQuery, _);

$(function() {
  $('button.clear').bind('click', function() {
    $('.events ul').empty();
  });
});
