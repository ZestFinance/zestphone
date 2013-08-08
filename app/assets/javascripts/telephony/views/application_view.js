Zest.Telephony.Views.ApplicationView = Backbone.View.extend({
  el: '#telephony-widget',

  initialize: function() {
    if (! this.el) {
      var logger = this.options.logger || console;
      logger.log("No root element to create the telephony widget");
      return;
    }

    Zest.Telephony.Push.init();
  },

  disableCallControl: function(opts) {
    this.widgetView.disableCallControl(opts);
  },

  render: function() {
    var $el = $(this.el);
    this.widgetView = new Zest.Telephony.Views.WidgetView({
      loanId: $el.data("loan_id"),
      csrId: $el.data("csr_id"),
      agentNumber: $el.data("agent_phone_number")
    });
    $el.append(this.widgetView.render().el);
    return this;
  }
});

Zest.Telephony.Application = (function () {
  var instance;

  return {
    init: function(agent) {
      var $widgetWrapper = $("#telephony-widget");
      agent = agent || this.setupAgent();

      agent.isValid({
        done_callback: $.proxy(this.done, this),
        fail_callback: $.proxy(this.fail, this)
      });
    },

    setupAgent: function() {
      var $widgetWrapper = $("#telephony-widget");

      return new Zest.Telephony.Models.Agent({
        csr_id: $widgetWrapper.data('csr_id'),
        csr_type: $widgetWrapper.data('csr_type'),
        csr_generate_caller_id: $widgetWrapper.data('agent_generate_caller_id'),
        csr_name: $widgetWrapper.data('agent_name'),
        csr_phone_number: $widgetWrapper.data('agent_phone_number'),
        csr_phone_ext: $widgetWrapper.data('agent_phone_ext'),
        csr_sip_number: $widgetWrapper.data('agent_sip_number'),
        csr_call_center_name: $widgetWrapper.data('agent_call_center_name'),
        csr_phone_type: $widgetWrapper.data('agent_phone_type') || "",
        csr_transferable_agents: JSON.stringify($widgetWrapper.data('agent_transferable_agents') || [])
      });
    },

    getInstance: function () {
      if ( !instance ) {
        instance = new Zest.Telephony.Views.ApplicationView();
      }
      return instance;
    },

    done: function(data) {
      this.getInstance().render();
      $(document).trigger("telephony:WidgetReady", { conversation_id: data.conversation_id });
    },

    fail: function(xhr, testStatus) {
      var body = JSON.parse(xhr.responseText);
      $("#telephony-widget").text(body.errors);
    }
  };
})();
