describe("Zest.Telephony.Views.TransferView", function() {
  var view;
  var request;

  beforeEach(function() {
    setFixtures('<div id="transfer"></div>');
    view = new Zest.Telephony.Views.TransferView({
      el: $("#transfer")
    });

    jasmine.Ajax.useMock();

    view.render();

    request = mostRecentAjaxRequest();
    var data = [
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
    ];
    request.response({status: 200, responseText: JSON.stringify(data)});
  });

  describe("selecting agent by pressing the enter key", function() {
    it("selects the best matched agent", function() {
      $('form').submit();

      expect($('input[name=selected_agent]').val()).toMatch(/abc/);
    });
  });

  describe("agents list", function() {
    describe("when agent is not selected", function() {
      it("does not show the initial transfer button", function() {
        expect($('#telephony-transfer')).toContain("span.controls.hidden");
      });

      it("shows the list of agents", function() {
        var $agents = $("li", view.el);
        expect($agents[0].innerHTML).toMatch(/abc/);
        expect($agents[1].innerHTML).toMatch(/xyz/);
      });
    });

    describe("when agent is selected", function() {
      var agent;

      beforeEach(function() {
        agent = new Zest.Telephony.Models.Agent({
          name: "Bruce",
          status: "available",
          phone_ext: "14"
        });
      });

      it("displays the selected agent's info", function() {
        $('#transfer').trigger("agentDidSelect", agent);

        expect(view.$('input[name=selected_agent]')).toHaveValue(agent.displayText());
      });

      it("disables the filter", function() {
        $('#transfer').trigger("agentDidSelect", agent);

        expect(view.$('input[name=selected_agent]')).toBeDisabled();
      });

      it("display agent status", function() {
        $('#transfer').trigger("agentDidSelect", agent);
        expect(view.$('form .agent-input span')).toHaveClass('icon-user available');
      });

      describe("agent is available", function() {
        it("defaults to two-step", function() {
          $('#transfer').trigger("agentDidSelect", agent);

          expect(view.$('#transfer_type_two_step')).toBeChecked();
          expect(view.$('#transfer_type_two_step')).not.toBeDisabled();
          expect(view.$('#transfer_type_one_step')).not.toBeChecked();
        });
      });

      describe("agent is not available", function() {
        it("disables the 2-step radio", function() {
          agent.set({status: "not_available"});

          $('#transfer').trigger("agentDidSelect", agent);

          expect(view.$('#transfer_type_one_step')).toBeChecked();
          expect(view.$('#transfer_type_two_step')).toBeDisabled();
          expect(view.$('#transfer_type_two_step')).not.toBeChecked();
        });
      });
    });

    describe("backspace button", function() {
      var agent;

      beforeEach(function() {
        agent = new Zest.Telephony.Models.Agent({
          name: "Bruce",
          status: "available",
          phone_ext: "14"
        });
      });

      it("is not shown when agent is not selected", function() {
        expect(view.$('form span.backspace')).toHaveClass('hidden');
      });

      it("is visible when agent is selected", function() {
        $('#transfer').trigger("agentDidSelect", agent);
        expect(view.$('form span.backspace')).not.toHaveClass('hidden');
      });

      it("handles click event", function() {
        $('#transfer').trigger("agentDidSelect", agent);

        spyOn(view, 'render');
        $('span.backspace').click();
        expect(view.transfer.get("selectedAgent")).toBeNull();
        expect(view.render).toHaveBeenCalled();
      });
    });
  });

  describe("when initiating a transfer", function() {
    describe('to an transferrable agent', function() {
      beforeEach(function() {
        var agent = new Zest.Telephony.Models.Agent({
          name: "Bruce",
          status: "available",
          phone_ext: "14"
        });
        $('#transfer').trigger("agentDidSelect", agent);

        view.$('form #transfer_type_one_step').click();
        view.$('button.initiate-transfer').click();
      });

      it("saves the transfer", function() {
        expect(view.transfer.get('transferType')).toEqual('one_step');
      });
    });

    describe('to an untransferrable agent', function() {
      var transferFailedSpy;

      beforeEach(function() {
        var agent = new Zest.Telephony.Models.Agent({
          name: "Bruce",
          status: "available",
          phone_ext: "14"
        });
        $('#transfer').trigger("agentDidSelect", agent);

        transferFailedSpy = jasmine.createSpy('transferFailed');
        $(document).bind('transferFailed', transferFailedSpy);

        view.$('form #transfer_type_one_step').click();
        view.$('button.initiate-transfer').click();
      });

      it("triggers a transfer failed event", function() {
        var transferRequest = mostRecentAjaxRequest();
        var responseBody = {
          errors: ['Agent is unavailable']
        }
        transferRequest.response({ status: 422,
                                   responseText: JSON.stringify(responseBody)});
        expect(transferFailedSpy).toHaveBeenCalled();
        var call = transferFailedSpy.mostRecentCall;
        expect(call.args[1]).toMatch(/agent is unavailable/i);
      });
    });
  });
});

