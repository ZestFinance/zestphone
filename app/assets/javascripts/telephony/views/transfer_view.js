Zest.Telephony.Views.TransferView = Backbone.View.extend({
  template: JST["templates/telephony/transfer_view"],

  events: {
    "submit": "selectBestMatchedAgent",
    "keyup input[name=selected_agent]": "filterAgents",
    "click button.initiate-transfer": "initiateTransfer",
    "click .backspace": "clearSelectedAgent",
    "click input[name=transfer_type]": "setTransferType"
  },

  initialize: function(option) {
    this.transfer = new Zest.Telephony.Models.Transfer({conversationId: option.conversationId});

    $(this.el).bind("agentDidSelect", $.proxy(this.setSelectedAgent, this));
  },

  rebindEvents: function() {
    this.delegateEvents(this.events);
    $(this.el).bind("agentDidSelect", $.proxy(this.setSelectedAgent, this));
  },

  selectBestMatchedAgent: function(event) {
    this.agentsView.selectBestMatched();
    return false;
  },

  clearSelectedAgent: function(event) {
    this.transfer.set({selectedAgent: null});
    this.render();
  },

  filterAgents: function(event) {
    if (event.keyCode == 13) return;

    var query = $(event.currentTarget).val();
    this.search(query);
  },

  search: function(query) {
    this.agentsView.filter(query);
  },

  setSelectedAgent: function(evt, selectedAgent) {
    this.transfer.set({selectedAgent: selectedAgent});
    this.render();
  },

  initiateTransfer: function(evt) {
    evt.preventDefault();
    evt.stopPropagation();

    var transferType = this.$('form input[name=transfer_type]:checked').val();
    var that = this;
    this.transfer.save({ transferType: transferType },
                       { success: function() {
                           $(document).trigger("transferInitiated");
                         },
                         error: function(model, xhr) {
                           var body = JSON.parse(xhr.responseText);
                           $(document).trigger('transferFailed', body.errors[0]);
                         }
                       });
    return false;
  },

  setTransferType: function(evt) {
    this.transfer.set({transferType: $(evt.currentTarget).val()});
  },

  render: function() {
    var selectedAgent = this.transfer.get("selectedAgent");
    var agentStatus = (typeof selectedAgent === "undefined" || selectedAgent === null) ?
      "" : "icon-user " + selectedAgent.get('status');
    var html = this.template({transfer: this.transfer, agentStatus: agentStatus});
    this.el.html(html);

    if (!this.transfer.get("selectedAgent")) {
      this.agentsView = new Zest.Telephony.Views.AgentsView(
        {
          el: $(".agents-wrapper"),
          currentAgentId: $("#telephony-widget").data("csr_id")
        });
      this.agentsView.render();
    }
  }
});
