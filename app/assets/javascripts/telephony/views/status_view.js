Zest.Telephony.Views.StatusView = Backbone.View.extend({
  className: 'agent-status-wrapper',

  events: {
    'click button' : 'toggleAvailable'
  },

  template: JST["templates/telephony/status_view"],

  initialize: function (options) {
    this.agent = new Zest.Telephony.Models.Agent({csr_id: options.csrId});
    this.agent.bind("change", this.render, this);

    $(document).bind("telephony:csrDidChangeStatus", $.proxy(this.renderStatus, this));
    $(document).bind("telephony:csrNotAvailable", $.proxy(this.setNotAvailable, this));
    $(document).bind("telephony:toggleCsrStatus", $.proxy(this.toggleAvailable, this));
  },

  toggleAvailable: function(event) {
    event.preventDefault();
    this.agent.toggleAvailable();
  },

  setNotAvailable: function() {
    this.agent.updateStatus();
  },

  renderStatus: function(event, data) {
    this.agent.set(data);
  },

  render: function() {
    $(this.el).html(this.template({ agent: this.agent }));
    return this;
  }
});
