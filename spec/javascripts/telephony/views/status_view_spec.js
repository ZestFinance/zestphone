describe("Zest.Telephony.Views.StatusView", function() {
  describe("toggle status", function() {
    var view;

    beforeEach(function() {
      setFixtures('<div id="status"></div>');
      view = new Zest.Telephony.Views.StatusView({csrId: 200, el: $("#status")});
      view.render();
    })

    it("handles status change via the button click", function() {
      spyOn(view.agent, 'toggleAvailable');
      view.$("button").click();

      expect(view.agent.toggleAvailable).toHaveBeenCalled();
    });

    it("handles status change from Pusher event", function() {
      $(document).trigger("telephony:csrDidChangeStatus", [{status: "some_status"}]);
      expect(view.$("button")).toHaveText("Some status");
    });

    describe("on a call", function() {
      it("disbales the button", function() {
        $(document).trigger("telephony:csrDidChangeStatus", [{status: "on_a_call"}]);
        expect(view.$('button')).toBeDisabled();
      });
    });
  });
});
