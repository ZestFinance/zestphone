describe("Zest.Telephony.Views.TwilioClientView", function() {
  describe("#initialize", function() {
    var view;

    beforeEach(function() {
      jasmine.Ajax.useMock();
      setFixtures("<div class='wrapper'> </div>");
      view = new Zest.Telephony.Views.TwilioClientView({
        csrId: 123
      });
    });

    it("retrieves a twilio token for an agent", function() {
      var request = mostRecentAjaxRequest();
      expect(request.url).toBe('/zestphone/twilio_client/token?csr_id=123');
    });
  });

  describe("#deviceAnswer", function() {
    var view;
    var conn = { accept: function(){} };

    beforeEach(function() {
      jasmine.Ajax.useMock();
      setFixtures("<div class='wrapper'> </div>");
      //agent = { onACall: function() {} };
      view = new Zest.Telephony.Views.TwilioClientView({
        csrId: 123
      });
      view.connection = conn;
    });

    it("registers a function to confirm a page reload", function() {
      spyOn(view, 'disallowBrowserReload');
      view.deviceAnswer();

      expect(view.disallowBrowserReload).toHaveBeenCalled();
    });

    it("disables the answer button", function() {
      view.deviceAnswer();

      expect(view.$('button.answer')).toBeDisabled();
      expect(view.$('button.answer')).not.toHaveClass('hidden');
    });
  });

  describe("#deviceHangup", function() {
    var view;

    beforeEach(function() {
      window.Twilio = { Device: { disconnectAll: function() {} } };
      jasmine.Ajax.useMock();
      setFixtures("<div class='wrapper'> </div>");
      view = new Zest.Telephony.Views.TwilioClientView({
        csrId: 123
      });
    });

    afterEach(function() {
      window.Twilio = null;
    });

    it("unregisters a function to confirm a page reload", function() {
      spyOn(view, 'allowBrowserReload');
      view.deviceHangup();

      expect(view.allowBrowserReload).toHaveBeenCalled();
    });

    it("hides the hangup button", function() {
      view.deviceHangup();

      expect(view.$('button.hangup')).toHaveClass('hidden');
    });
  });
});
