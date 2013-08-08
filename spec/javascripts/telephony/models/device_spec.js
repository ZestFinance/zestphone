describe("Zest.Telephony.Models.Device", function() {
  describe("#state", function() {
    it("defaults to 'disabled_by_default'", function() {
      var device = new Zest.Telephony.Models.Device();
      expect(device.state()).toBe("disabled_by_default");
    });
  });

  describe("#uiShowAnswerButton", function() {
    var device;

    beforeEach(function() {
      device = new Zest.Telephony.Models.Device();
    });

    it("shows the answer button on 'ready'", function() {
      device.set({ state: 'ready' });
      expect(device.uiShowAnswerButton()).toBe('');
    });

    it("shows the answer button on 'error'", function() {
      device.set({ state: 'error' });
      expect(device.uiShowAnswerButton()).toBe('');
    });

    it("shows the answer button on 'disconnect'", function() {
      device.set({ state: 'disconnect' });
      expect(device.uiShowAnswerButton()).toBe('');
    });

    it("shows the answer button on 'incoming'", function() {
      device.set({ state: 'incoming' });
      expect(device.uiShowAnswerButton()).toBe('');
    });

    it("shows the answer button on 'answering'", function() {
      device.set({ state: 'answering' });
      expect(device.uiShowAnswerButton()).toBe('');
    });
  });

  describe("#uiDisableAnswerButton", function() {
    var device;

    beforeEach(function() {
      device = new Zest.Telephony.Models.Device();
    });

    it("enables the answer button on 'incoming'", function() {
      device.set({ state: 'incoming' });
      expect(device.uiDisableAnswerButton()).toBe('');
    });
  });

  describe("#uiShowHangupButton", function() {
    var device;

    beforeEach(function() {
      device = new Zest.Telephony.Models.Device();
    });

    it("shows the hangup button on 'connect'", function() {
      device.set({ state: 'connect' });
      expect(device.uiShowHangupButton()).toBe('');
    });
  });

  describe("#uiDisableHangupButton", function() {
    var device;

    beforeEach(function() {
      device = new Zest.Telephony.Models.Device();
    });

    it("enables the hangup button on 'connect'", function() {
      device.set({ state: 'connect' });
      expect(device.uiDisableHangupButton()).toBe('');
    });
  });
});
