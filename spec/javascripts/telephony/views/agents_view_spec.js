describe("Zest.Telephony.Views.AgentsView", function() {
  describe("#initialize", function() {
    var view;

    beforeEach(function() {
      jasmine.Ajax.useMock();
      setFixtures("<div class='wrapper'> </div>");
    });

    describe("when agents are not provided", function() {
      it("request a list of transferable agents for an agent", function() {
        view = new Zest.Telephony.Views.AgentsView({
          el: $('.wrapper'),
          currentAgentId: 123
        });
        var request = mostRecentAjaxRequest();

        expect(request.url).toBe('/zestphone/agents?csr_id=123');
      });
    });
  });

  describe("filter", function() {
    var agents;
    var view;

    beforeEach(function() {
      setFixtures("<div class='wrapper'> </div>");

      agents = new Zest.Telephony.Collections.Agents([
        {
          id: 123,
          name: 'abc',
          csr_type: 'A'
        },
        {
          id: 456,
          name: 'xyz',
          csr_type: 'B'
        }
      ]);

      view = new Zest.Telephony.Views.AgentsView({
        el: $('.wrapper'),
        agents: agents
      });
    });

    describe("when the query is empty", function() {
      it("shows all agents", function() {
        spyOn(view.agents, "reset");

        view.filter("");
        expect(view.agents.reset).toHaveBeenCalledWith(agents.toJSON());
      });
    });

    describe("when query is provided", function() {
      it("shows matched agents only", function() {
        spyOn(view.agents, "reset");

        view.filter("xyz");
        expect(view.agents.reset).toHaveBeenCalledWith([agents.at(1).toJSON()]);
      });
    });
  });

  describe("#render", function(){
    var agents, view;

    beforeEach(function() {
      setFixtures("<div class='wrapper'/>");

      agents = new Zest.Telephony.Collections.Agents([
        {
          id: 123,
          name: 'abc',
          csr_id: 1000,
          csr_type: 'A'
        },
        {
          id: 456,
          name: 'xyz',
          csr_id: 1001,
          csr_type: 'B'
        }
      ]);

      view = new Zest.Telephony.Views.AgentsView({
        el: $('.wrapper'),
        currentAgentId: 1000,
        agents: agents
      });
    });

    it ("excludes the current agent", function() {
      view.render();
      expect($('li', view.el).length).toBe(1);
    });
  });
});
