describe('Zest.Telephony.Views.WidgetView', function () {
  describe('#render', function () {
    var widgetView;

    beforeEach(function () {
      widgetView = new Zest.Telephony.Views.WidgetView();
      widgetView.render();
    });

    it('adds the widget CSS styles', function() {
      var widgetCss = _.last($('head link'));
      expect($(widgetCss)).toHaveAttr('href', '/assets/telephony/widget.css');
    });

    it('adds the conversation view', function() {
      expect($(widgetView.el)).toContain('.conversation-wrapper');
    });
  });
});

