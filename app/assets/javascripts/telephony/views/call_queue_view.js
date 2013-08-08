Zest.Telephony.Views.CallQueueView = Backbone.View.extend({
  className: 'call-queue-wrapper',

  template: JST["templates/telephony/call_queue_view"],

  initialize: function() {
    this.queue = { size: 99 };
    $(document)
      .bind("telephony:QueueChange", $.proxy(this.updateQueue, this));
  },

  updateQueue: function(event, data) {
    this.queue.size = data.size;
    this.render();
  },

  render: function() {
    $(this.el).html(this.template({ queue: this.queue }));
    return this;
  }
});
