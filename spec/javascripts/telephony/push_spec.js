describe("Zest.Telephony.Push", function() {
  describe('#init', function () {
    var socket;

    beforeEach(function() {
      setFixtures('<div id="telephony-widget" ' +
        'data-csr_id="123" data-csr_type="A" data-agent_name="Some Agent" ' +
        'data-agent_phone_number="555-555-1234" data-agent_phone_ext="010" ' +
        'data-agent_sip_number="0432" data-agent_call_center_name="Some Place" ' +
        'data-agent_transferable_agents="[1]"' +
        'data-agent_generate_caller_id="true"' +
        'data-agent_default_status="not_available"' +
        'data-agent_phone_type="phone" />');

      Zest.Telephony.Config.PUSHER_APP_KEY = "app_key";
      socket = new Pusher(Zest.Telephony.PUSHER_APP_KEY);
    });

    it("initializes the Pusher socket with CSR specific auth params", function () {
      Zest.Telephony.Push.init();
      params = Zest.Telephony.Push.socket.options.auth.params;
      expect(params.csr_id).toEqual(123);
      expect(params.csr_default_status).toEqual('not_available');
    });

    describe("a CSR channel", function() {
      var csrChannel;
      var data;

      beforeEach(function () {
        csrChannel = socket.subscribe('csrs-123');
        data = { event_id: 1 };
      });

      describe("given a CSR status change event", function() {
        var statusChangeHandler;

        beforeEach(function() {
          statusChangeHandler = jasmine.createSpy("statusChange");
          $(document).on("telephony:csrDidChangeStatus", statusChangeHandler);

          Zest.Telephony.Push.init(socket);
          _.extend(data, {
            status: 'available',
            timestamp: new Date().getTime()
          });
          Zest.Telephony.Push.lastStatusChangeEventAt = new Date().getTime() - 1000;
          csrChannel.emit("statusChange", data);
        });

        it("emits a telephony:csrDidChangeStatus event", function() {
          expect(statusChangeHandler).toHaveBeenCalled();
          expect(statusChangeHandler.mostRecentCall.args[1]).toEqual(data);
        });

        it('updates the last status change event time', function() {
          expect(Zest.Telephony.Push.lastStatusChangeEventAt).toEqual(data.timestamp);
        });
      });

      describe("given a CSR status change event from the past", function() {
        var statusChangeHandler;

        beforeEach(function() {
          statusChangeHandler = jasmine.createSpy("statusChange");
          $(document).on("telephony:csrDidChangeStatus", statusChangeHandler);

          Zest.Telephony.Push.init(socket);
          _.extend(data, {
            status: 'available',
            timestamp: new Date().getTime() - 1000
          });
          Zest.Telephony.Push.lastStatusChangeEventAt = new Date().getTime();

          csrChannel.emit("statusChange", data);
        });

        it("does not emit a telephony event", function() {
          expect(statusChangeHandler).not.toHaveBeenCalled();
        });
      });

      describe("given an initialize widget event", function() {
        var initializeHandler;

        beforeEach(function() {
          initializeHandler = jasmine.createSpy("InitializeWidget");
          $(document).on("telephony:InitializeWidget", initializeHandler);
          Zest.Telephony.Push.init(socket);

          csrChannel.emit("InitializeWidget");
        });

        it("emits a telephony:InitializeWidget event", function() {
          expect(initializeHandler).toHaveBeenCalled();
        });

        it("does not update the last event id", function() {
          expect(Zest.Telephony.Push.lastCallEventId).toEqual(0);
        });
      });

      describe("given a call connect event", function() {
        var connectHandler;

        beforeEach(function() {
          connectHandler = jasmine.createSpy("Connect");
          $(document).on("telephony:Connect", connectHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {
            conversation_id: 1,
            call_id: 10,
            conversation_state: 'connecting'
          });

          csrChannel.emit("Connect", data);
        });

        it("emits a telephony:Connect event", function() {
          expect(connectHandler).toHaveBeenCalled();
          expect(connectHandler.mostRecentCall.args[1]).toEqual(data);
        });

        it("updates the last event id", function() {
          expect(Zest.Telephony.Push.lastCallEventId).toEqual(1);
        });
      });

      describe("given a conversation start event", function() {
        var startHandler;

        beforeEach(function() {
          startHandler = jasmine.createSpy("Start");
          $(document).on("telephony:Start", startHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {
            conversation_id: 1,
            call_id: null,
            conversation_state: 'in_progress'
          });

          csrChannel.emit("Start", data);
        });

        it("emits a telephony:Start event", function() {
          expect(startHandler).toHaveBeenCalled();
          expect(startHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a call ended event", function() {
        var terminateHandler;

        beforeEach(function() {
          terminateHandler = jasmine.createSpy("Terminate");
          $(document).on("telephony:Terminate", terminateHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {
            conversation_id: 1,
            call_id: 10,
            conversation_state: 'in_progress'
          });

          csrChannel.emit("Terminate", data);
        });

        it("emits a telephony:Terminate event", function() {
          expect(terminateHandler).toHaveBeenCalled();
          expect(terminateHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a initate two step transfer event", function() {
        var twoStepInitiatedHandler;

        beforeEach(function() {
          twoStepInitiatedHandler = jasmine.createSpy("InitiateTwoStepTransfer");
          $(document).on("telephony:InitiateTwoStepTransfer", twoStepInitiatedHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {
            agent_name: "Some Name",
            agent_ext: 10
          });

          csrChannel.emit("InitiateTwoStepTransfer", data);
        });

        it("emits a telephony:InitiateTwoStepTransfer event", function() {
          expect(twoStepInitiatedHandler).toHaveBeenCalled();
          expect(twoStepInitiatedHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a two step transfer failed event", function() {
        var twoStepFailedHandler;

        beforeEach(function() {
          twoStepFailedHandler = jasmine.createSpy("FailTwoStepTransfer");
          $(document).on("telephony:FailTwoStepTransfer", twoStepFailedHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {});

          csrChannel.emit("FailTwoStepTransfer", data);
        });

        it("emits a telephony:FailTwoStepTransfer event", function() {
          expect(twoStepFailedHandler).toHaveBeenCalled();
          expect(twoStepFailedHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a two step transfer completed event", function() {
        var twoStepCompletedHandler;

        beforeEach(function() {
          twoStepCompletedHandler = jasmine.createSpy("CompleteTwoStepTransfer");
          $(document).on("telephony:CompleteTwoStepTransfer", twoStepCompletedHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {
            agent_name: "Some Name",
            agent_ext: 10
          });

          csrChannel.emit("CompleteTwoStepTransfer", data);
        });

        it("emits a telephony:CompleteTwoStepTransfer event", function() {
          expect(twoStepCompletedHandler).toHaveBeenCalled();
          expect(twoStepCompletedHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a leave two step transfer event", function() {
        var leaveTwoStepHandler;

        beforeEach(function() {
          leaveTwoStepHandler = jasmine.createSpy("LeaveTwoStepTransfer");
          $(document).on("telephony:LeaveTwoStepTransfer", leaveTwoStepHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {});

          csrChannel.emit("LeaveTwoStepTransfer", data);
        });

        it("emits a telephony:LeaveTwoStepTransfer event", function() {
          expect(leaveTwoStepHandler).toHaveBeenCalled();
          expect(leaveTwoStepHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a customer left two step transfer event", function() {
        var customerLeftTwoStepTransferHandler;

        beforeEach(function() {
          customerLeftTwoStepTransferHandler = jasmine.createSpy("CustomerLeftTwoStepTransfer");
          $(document).on("telephony:CustomerLeftTwoStepTransfer", customerLeftTwoStepTransferHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {});

          csrChannel.emit("CustomerLeftTwoStepTransfer", data);
        });

        it("emits a telephony:CustomerLeftTwoStepTransfer event", function() {
          expect(customerLeftTwoStepTransferHandler).toHaveBeenCalled();
          expect(customerLeftTwoStepTransferHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given an initiate one step transfer event", function() {
        var initiateOneStepTransferHandler;

        beforeEach(function() {
          initiateOneStepTransferHandler = jasmine.createSpy("InitiateOneStepTransferHandler");
          $(document).on("telephony:InitiateOneStepTransfer", initiateOneStepTransferHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {});

          csrChannel.emit("InitiateOneStepTransfer", data);
        });

        it("emits a telephony:InitiateOneStepTransfer event", function() {
          expect(initiateOneStepTransferHandler).toHaveBeenCalled();
          expect(initiateOneStepTransferHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a complete one step transfer event", function() {
        var completeOneStepTransferHandler;

        beforeEach(function() {
          completeOneStepTransferHandler = jasmine.createSpy("CompleteOneStepTransferHandler");
          $(document).on("telephony:CompleteOneStepTransfer", completeOneStepTransferHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {});

          csrChannel.emit("CompleteOneStepTransfer", data);
        });

        it("emits a telephony:CompleteOneStepTransfer event", function() {
          expect(completeOneStepTransferHandler).toHaveBeenCalled();
          expect(completeOneStepTransferHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a one step transfer failed event", function() {
        var oneStepFailedHandler;

        beforeEach(function() {
          oneStepFailedHandler = jasmine.createSpy("FailOneStepTransfer");
          $(document).on("telephony:FailOneStepTransfer", oneStepFailedHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {});

          csrChannel.emit("FailOneStepTransfer", data);
        });

        it("emits a telephony:FailOneStepTransfer event", function() {
          expect(oneStepFailedHandler).toHaveBeenCalled();
          expect(oneStepFailedHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given a leave voicemail event", function() {
        var leaveVoicemailHandler;

        beforeEach(function() {
          leaveVoicemailHandler = jasmine.createSpy("LeaveVoicemailHandler");
          $(document).on("telephony:LeaveVoicemail", leaveVoicemailHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {});

          csrChannel.emit("LeaveVoicemail", data);
        });

        it("emits a telephony:LeaveVoicemail event", function() {
          expect(leaveVoicemailHandler).toHaveBeenCalled();
          expect(leaveVoicemailHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given an answer event", function() {
        var answerHandler;

        beforeEach(function() {
          answerHandler = jasmine.createSpy("AnswerHandler");
          $(document).on("telephony:Answer", answerHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, {});

          csrChannel.emit("Answer", data);
        });

        it("emits a telephony:Answer event", function() {
          expect(answerHandler).toHaveBeenCalled();
          expect(answerHandler.mostRecentCall.args[1]).toEqual(data);
        });
      });

      describe("given an event from the past", function() {
        var connectHandler;

        beforeEach(function() {
          connectHandler = jasmine.createSpy("ConnectHandler");
          $(document).on("telephony:Connect", connectHandler);
          Zest.Telephony.Push.init(socket);
          _.extend(data, { event_id: -1 });

          csrChannel.emit("Connect", data);
        });

        it("does not emit a telephony event", function() {
          expect(connectHandler).not.toHaveBeenCalled();
        });
      });
    });

    describe("queue change", function() {
      var allCsrsChannel;
      var csrChannel;
      var data;
      var queueHandler;

      beforeEach(function () {
        allCsrsChannel = socket.subscribe('csrs');
        csrChannel = socket.subscribe('csrs-123');
        data = { event_id: 1 };
        queueHandler = jasmine.createSpy("QueueChangeHandler");
        $(document).on("telephony:QueueChange", queueHandler);
        Zest.Telephony.Push.init(socket);
      });

      describe("event received", function() {
        beforeEach(function() {
          _.extend(data, {});
        });

        it("emits a telephony:QueueChange event to all CSRs", function() {
          allCsrsChannel.emit("QueueChange", data);
          expect(queueHandler).toHaveBeenCalled();
          expect(queueHandler.mostRecentCall.args[1]).toEqual(data);
        });

        it("emits a telephony:QueueChange event to a CSRs", function() {
          csrChannel.emit("QueueChange", data);
          expect(queueHandler).toHaveBeenCalled();
          expect(queueHandler.mostRecentCall.args[1]).toEqual(data);
        });

        it("updates the last event id", function() {
          allCsrsChannel.emit("QueueChange", data);
          expect(Zest.Telephony.Push.lastQueueChangeEventId).toEqual(1);
        });
      });

      describe("old event received", function() {
        beforeEach(function() {
          _.extend(data, { event_id: -1 });
          allCsrsChannel.emit("QueueChange", data);
        });

        it("does not emit a change event", function() {
          expect(queueHandler).not.toHaveBeenCalled();
        });
      });
    });
  });
});
