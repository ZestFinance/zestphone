describe("Zest.Telephony.Models.Transfer", function() {
  describe("#selectedAgentDisplayText", function() {
    describe("when agent is selected", function() {
      it("displays the agent's display name", function() {
        var agent = new Zest.Telephony.Models.Agent({
          name: "Bruce",
          csr_type: "A",
          phone_ext: "14"
        });
        var transfer = new Zest.Telephony.Models.Transfer({selectedAgent: agent});
        expect(transfer.selectedAgentDisplayText()).toBe("A Bruce x14");
      });
    })

    describe("when agent is not selected", function() {
      it("displays an empty string", function() {
        var transfer = new Zest.Telephony.Models.Transfer();
        expect(transfer.selectedAgentDisplayText()).toBe("");
      })
    })
  })
});
