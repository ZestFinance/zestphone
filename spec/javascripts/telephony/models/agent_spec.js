describe("Zest.Telephony.Models.Agent", function() {
  describe("#status", function() {
    it("defaults to 'offline'", function() {
      var agent = new Zest.Telephony.Models.Agent();
      expect(agent.status()).toBe("loading...");
    });
  });

  describe("#url", function() {
    it("uses the correct path", function() {
      var agent = new Zest.Telephony.Models.Agent({csr_id: 123});
      expect(agent.url()).toBe("/zestphone/agents/123");
    });
  });

  describe("#toggleAvailable", function() {
    var agent;
    var request;
    var data;

    beforeEach(function() {
      jasmine.Ajax.useMock();
      agent = new Zest.Telephony.Models.Agent({csr_id: 123});
      spyOn(agent, 'done');

      agent.toggleAvailable();
      request = mostRecentAjaxRequest();
      data = { status: "available" };
      request.response({status: 200, responseText: JSON.stringify(data)});
    })

    it("trigger an event", function() {
      expect(agent.done).toHaveBeenCalled();
      expect(agent.done.mostRecentCall.args[0]).toEqual(data);
      expect(request.method).toEqual('PUT');
      expect(request.params).toEqual('event=toggle_available');
      expect(request.url).toEqual('/zestphone/agents/123/status');
    });
  });
});
