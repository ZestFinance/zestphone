Zest.Telephony.Views.ConversationButtonsView = Backbone.View.extend({
  className: 'buttons-wrapper',

  template: JST["templates/telephony/conversation_buttons_view"],

  initialize: function(options) {
    this.conversation = options.conversation;
    this.conversation.bind("change", $.proxy(this.render, this));
  },

  render: function() {
    $(this.el).html(this.template({conversation: this.conversation}));
    return this;
  }
});
