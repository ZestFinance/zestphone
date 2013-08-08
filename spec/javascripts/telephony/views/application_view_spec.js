describe('Zest.Telephony.Views.ApplicationView', function () {
  describe('#initialize', function() {
    describe('on a page that does not have a "#telephony-widget"', function() {
      var logger = { log: function() {} };

      beforeEach(function() {
        spyOn(logger, 'log');
        new Zest.Telephony.Views.ApplicationView({logger: logger});
      });

      it('logs an error', function() {
        expect(logger.log).toHaveBeenCalled();
      });
    });
  });

  describe('#render', function () {
    var applicationView;

    beforeEach(function () {
      setFixtures('<div id="telephony-widget" />');

      applicationView = new Zest.Telephony.Views.ApplicationView();
      applicationView.render();
    });

    it('displays the telephony widget', function () {
      expect($(applicationView.el)).toContain('.telephony-widget-container');
    });
  });

  describe("#init", function() {
    var agent;

    beforeEach(function () {
      setFixtures('<div id="telephony-widget" />');
      agent = new Zest.Telephony.Models.Agent();

      spyOn(agent, 'isValid');

      Zest.Telephony.Application.init(agent);
    });

    it("validates agent's data", function() {
      expect(agent.isValid).toHaveBeenCalled();
    });
  });

  describe("#setupAgent", function() {
    beforeEach(function() {
      setFixtures('<div id="telephony-widget" ' +
        'data-csr_id="123" data-csr_type="A" data-agent_name="Some Agent" ' +
        'data-agent_phone_number="555-555-1234" data-agent_phone_ext="010" ' +
        'data-agent_sip_number="0432" data-agent_call_center_name="Some Place" ' +
        'data-agent_transferable_agents="[1]"' +
        'data-agent_generate_caller_id="true"' +
        'data-agent_phone_type="phone" />');
    });

    it("returns the agent with attributes from #telephony-widget container", function() {
      agent = Zest.Telephony.Application.setupAgent();

      expect(agent.get('csr_generate_caller_id')).toBeTruthy();
      expect(agent.get('csr_name')).toEqual('Some Agent');
      expect(agent.get('csr_phone_ext')).toEqual('010');
      expect(agent.get('csr_type')).toEqual("A");
      expect(agent.get('csr_sip_number')).toEqual('0432');
      expect(agent.get('csr_call_center_name')).toEqual("Some Place");
      expect(agent.get('csr_phone_number')).toEqual("555-555-1234");
      expect(agent.get('csr_transferable_agents')).toEqual("[1]");
      expect(agent.get('csr_phone_type')).toEqual("phone");
    });
  });
});
