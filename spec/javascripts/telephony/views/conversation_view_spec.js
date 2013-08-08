describe("Zest.Telephony.Views.ConversationView", function() {
  describe("#render", function() {
    var view;

    beforeEach(function() {
      setFixtures('<div id="conversation-wrapper"></div>');
      view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
      view.render();
    });

    it("displays conversation controls", function() {
      expect(view.el).toContain("input[name=number]");
      expect(view.el).toContain("button.initiate-conversation");
    });

    it("does not display a conversation message", function() {
      expect(view.$('.friendly-message')).toHaveText("");
    });
  });

  describe('event handling', function() {
    describe("receiving an outbound telephony:Connect event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
        view.conversation.set({state: 'connecting'});
        var data = {
          conversation_id: 10,
          conversation_state: "connecting",
          call_id: 20,
          number: "1111111111"
        };

        $(document).trigger('telephony:Connect', data);
      });

      it("displays a ringing message", function() {
        expect(view.el).toHaveText(/Ringing/);
      });

      it("displays the phone number", function() {
        expect(view.$("[name='number']")).toHaveValue("1111111111");
      });
    });

    describe("receiving a telephony:InitializeWidget event", function () {
      var view;

      beforeEach(function () {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();

        view.friendlyMessage = "Call Ended";
        $(document).trigger('telephony:InitializeWidget');
      });

      it("clears the friendly message", function () {
        expect(view.$(".friendly-message")).toHaveText("");
      });
    });

    describe("receiving an inbound telephony:Connect event", function () {
      var view;

      beforeEach(function () {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
        var data = {
          conversation_id: 10,
          conversation_state: "connecting",
          number: "1111111111",
          call_id: 20
        };

        $(document).trigger('telephony:Connect', data);
      });

      it("displays the inbound number", function () {
        expect(view.$("[name='number']")).toHaveValue("1111111111");
      });
    });

    describe("receiving a telephony:Start event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
        var data = {
          conversation_id: 10,
          conversation_state: "connecting",
          call_id: 20,
          number: "1111111111"
        };

        $(document).trigger('telephony:Start', data);
      });

      it("displays a connected message", function() {
        expect(view.el).toHaveText(/Connected/);
      });

      it("displays the phone number", function() {
        expect(view.$("[name='number']")).toHaveValue("1111111111");
      });
    });

    describe("receiving a telephony:Terminate event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.conversation.set({ state: 'on_a_call',
                                isCancelable: true });
        view.render();

        var data = {
          conversation_id: 10
        };

        runs(function() {
          view.friendlyMessageFadeOutTime = 100;
          $(document).trigger('telephony:Terminate', data);
        });

        waitsFor(function() {
          return view.$('.friendly-message').css('opacity') < 1;
        }, "didn't fade out the call ended message");
      });

      it("fades outs a call ended message", function() {
        runs(function() {
          expect(view.el).toHaveText(/Call Ended/);
        });
      });

      it('re-displays the call button', function() {
        runs(function() {
          expect(view.$('.initiate-conversation')).not.toHaveClass('hidden');
        });
      });

      it("does not display the phone number", function() {
        runs(function() {
          expect(view.$("[name='number']")).toHaveValue("");
        });
      });

      it("does not display the cancel transfer button", function() {
        runs(function() {
          expect(view.$('.cancel-transfer')).toHaveClass('hidden');
        });
      });
    });

    describe("receiving a telephony:InitiateOneStepTransfer event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
      });

      describe("for agent 1", function() {
        beforeEach(function() {
          var data = {
            transferrer: true,
            agent_name: "Some Name",
            agent_ext: 10,
            agent_type: 'A',
            number: "1111111111"
          };

          $(view.el).text('Connected');
          $(document).trigger('telephony:InitiateOneStepTransfer', data);
        });

        it("does not display a one step transfer initiated message", function() {
          expect(view.el).toHaveText(/Connected/);
        });
      });

      describe("for agent 2", function() {
        beforeEach(function() {
          var data = {
            transferrer: false,
            agent_name: "Another Name",
            agent_ext: 11,
            agent_type: 'A',
            number: "1111111112"
          };

          $(document).trigger('telephony:InitiateOneStepTransfer', data);
        });

        it("displays a one step transfer initiated message", function() {
          expect(view.el).toHaveText(/1-step transfer from A - Another Name x11/);
        });

        it("displays the phone number", function() {
          expect(view.$("[name='number']")).toHaveValue("1111111112");
        });
      });
    });

    describe("receiving a telephony:CompleteOneStepTransfer event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
        var data = {
          agent_name: "Some Name",
          agent_ext: 10,
          agent_type: 'A',
          number: "1111111111"
        };

        $(document).trigger('telephony:CompleteOneStepTransfer', data);
      });

      it("displays a one step transfer completed message", function() {
        expect(view.el).toHaveText(/Connected/);
      });

      it("displays the phone number", function() {
        expect(view.$("[name='number']")).toHaveValue("1111111111");
      });
    });

    describe("receiving a telephony:FailOneStepTransfer event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
      });

      describe('for agent1', function() {
        beforeEach(function() {
          var data = {
            transferrer: true,
            agent_name: "Some Name",
            agent_ext: 10,
            agent_type: 'A',
            number: "1111111111"
          };

          $(document).trigger('telephony:FailOneStepTransfer', data);
        });

        it("does not display a one step transfer failed message", function() {
          expect(view.el).not.toHaveText(/Missed 1-step transfer/);
        });

        it('terminates its conversation', function() {
          expect(view.conversation.get('state')).toEqual('terminated');
        });
      });

      describe('for agent2', function() {
        beforeEach(function() {
          var data = {
            transferrer: false,
            agent_name: "Some Name",
            agent_ext: 10,
            agent_type: 'A',
            number: "1111111111"
          };

          $(document).trigger('telephony:FailOneStepTransfer', data);
        });

        it("displays a one step transfer failed message", function() {
          expect(view.el).toHaveText(/Missed 1-step transfer from A - Some Name x10/);
        });

        it('terminates its conversation', function() {
          expect(view.conversation.get('state')).toEqual('terminated');
        });
      });
    });

    describe("receiving a telephony:InitiateTwoStepTransfer event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
      });

      describe("for the initiator of the transfer", function() {
        beforeEach(function() {
          var data = {
            transferrer: true,
            agent_name: "Some Name",
            agent_ext: 10,
            agent_type: 'A',
            number: "1111111111"
          };

          $(document).trigger('telephony:InitiateTwoStepTransfer', data);
        });

        it("displays a two step transfer initiated message", function() {
          expect(view.el).toHaveText(/Ringing A - Some Name x10/);
        });

        it("displays the phone number", function() {
          expect(view.$("[name='number']")).toHaveValue("1111111111");
        });
      });

      describe("for the recipient of the transfer", function() {
        beforeEach(function() {
          var data = {
            transferrer: false,
            agent_name: "Some Name",
            agent_ext: 10,
            agent_type: 'A',
            number: "1111111111"
          };

          $(document).trigger('telephony:InitiateTwoStepTransfer', data);
        });

        it("displays a two step transfer initiated message", function() {
          expect(view.el).toHaveText(/2-step transfer from A - Some Name x10/);
        });

        it("displays the phone number", function() {
          expect(view.$("[name='number']")).toHaveValue("1111111111");
        });
      });
    });

    describe("receiving a telephony:FailTwoStepTransfer event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
      });

      describe('for agent1', function() {
        beforeEach(function() {
          var data = {
            transferrer: true,
            agent_name: "Agent 2",
            agent_ext: 10,
            number: "1111111111"
          };

          runs(function() {
            view.friendlyMessageFadeOutTime = 100;
            $(document).trigger('telephony:FailTwoStepTransfer', data);
          });

          waitsFor(function() {
            return view.$('.friendly-message').css('opacity') < 1;
          }, "didn't fade out the two step transfer failed message", 1000);
        });

        it("displays a two step transfer failed message", function() {
          expect(view.$('.friendly-message')).toHaveText("No Answer - Agent 2 x10");
        });

        it("displays agent2's phone number", function() {
          runs(function() {
            expect(view.$("[name='number']")).toHaveValue("1111111111");
          });
        });
      });

      describe('for agent2', function() {
        beforeEach(function() {
          var data = {
            transferrer: false,
            agent_name: "Other Name",
            agent_ext: 11,
            agent_type: 'B',
            number: "1111111111"
          };

          $(document).trigger('telephony:FailTwoStepTransfer', data);
        });

        it("displays a two step transfer failed message", function() {
          expect(view.el).toHaveText(/Missed 2-step transfer from B - Other Name x11/);
        });
      });
    });

    describe("receiving a telephony:CompleteTwoStepTransfer event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
        var data = {
          agent_name: "Some Name",
          agent_ext: 10,
          agent_type: 'A',
          number: "1111111111"
        };

        $(document).trigger('telephony:CompleteTwoStepTransfer', data);
      });

      it("displays a two step transfer completed message", function() {
        expect(view.el).toHaveText(/Connected to A - Some Name x10/);
      });

      it("displays the phone number", function() {
        expect(view.$("[name='number']")).toHaveValue("1111111111");
      });
    });

    describe("receiving a telephony:LeaveTwoStepTransfer event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
        var data = {
          number: "1111111111"
        };

        $(document).trigger('telephony:LeaveTwoStepTransfer', data);
      });

      it("displays a leave two step transfer message", function() {
        expect(view.el).toHaveText(/Connected/);
      });

      it("displays the phone number", function() {
        expect(view.$("[name='number']")).toHaveValue("1111111111");
      });
    });

    describe("receiving a telephony:CustomerLeftTwoStepTransfer event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
        var data = {
          agent_name: "Some Name",
          agent_ext: 10,
          agent_type: 'A',
          number: "1111111111"
        };

        $(document).trigger('telephony:CustomerLeftTwoStepTransfer', data);
      });

      it("displays a customer left two step transfer message", function() {
        expect(view.el).toHaveText(/Connected to A - Some Name x10/);
      });

      it("displays the phone number", function() {
        expect(view.$("[name='number']")).toHaveValue("1111111111");
      });
    });

    describe("receiving a telephony:ClickToCall event", function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView({el: $("#conversation-wrapper")});
        view.render();
        var data = {
          loan_id: '1',
          to: '3003004002',
          to_id: '9',
          to_type: 'borrower',
          callee_name: 'Some Name'
        };

        $(document).trigger('telephony:ClickToCall', data);
      });

      it("displays the callee name", function() {
        expect(view.el).toHaveText(/Some Name/);
      });

      it("updates the conversation", function() {
        var convo = view.conversation;
        expect(convo.get('to')).toBe('3003004002');
        expect(convo.get('toId')).toBe('9');
        expect(convo.get('toType')).toBe('borrower');
      });

      it("displays the phone number", function() {
        expect(view.$("[name='number']")).toHaveValue("3003004002");
      });
    });

    describe('receiving a transferFailed event from its TransferView subview', function() {
      var view;

      beforeEach(function() {
        setFixtures('<div id="conversation-wrapper"></div>');
        view = new Zest.Telephony.Views.ConversationView();
        view.render();

        $(document).trigger('transferFailed', 'Agent is unavailable');
      });

      it('displays a transfer failed message', function() {
        expect(view.$('.friendly-message')).toHaveText('Agent is unavailable');
      });
    });
  });

  describe("submitting a conversation", function() {
    var view;

    beforeEach(function() {
      setFixtures('<div id="conversation-wrapper" />');
      view = new Zest.Telephony.Views.ConversationView({loanId: 123});
      view.conversation.set({ state: 'not_initiated' });
      view.render();
      jasmine.Ajax.useMock();
    });

    describe('with a valid phone number', function() {
      beforeEach(function() {
        view.$('input[name=number]').val("300-300-4000");
      });

      it("creates a new conversation", function() {
        view.$('button.initiate-conversation').click();
        var request = mostRecentAjaxRequest();

        expect(request.url).toBe('/zestphone/conversations');
        expect(request.method).toBe('POST');
        expect(request.params).toMatch('loan_id=123');
      });

      it("disables the phone number input", function() {
        view.$('button.initiate-conversation').click();

        expect(view.$('input[name=number]')).toBeDisabled();
        expect(view.$('input[name=number]')).toHaveValue('300-300-4000');
      });

      it("disables the call button", function() {
        view.$('button.initiate-conversation').click();

        expect(view.$('button.initiate-conversation')).toBeDisabled();
      });
    });

    describe('with an invalid phone number', function() {
      beforeEach(function() {
        view.conversation.set({state: "not_initiated"});
        view.$('input[name=number]').val('');
        view.$('button.initiate-conversation').click();
      });

      it('displays an error message', function() {
        expect(view.$('.friendly-message')).toHaveText(/Please enter a 10-digit phone number/);
      });
    });
  });

  describe("submitting a conversation without a page reload", function() {
    var view;
    beforeEach(function() {
      setFixtures('<div class="conversation-wrapper" />');
      view = new Zest.Telephony.Views.ConversationView();
      view.render();
      view.$('input[name=number]').val("3003004000");
      jasmine.Ajax.useMock();
    });

    it("creates a new conversation every time", function() {
      var data = '{"id":110,"caller_call_id":238,"callee_call_id":239}';
      // First call
      view.$('button.initiate-conversation').click();
      firstCallRequest = mostRecentAjaxRequest();
      firstCallRequest.response({ status:200, responseText:data });
      expect(firstCallRequest.url).toBe('/zestphone/conversations');

      // Enable calling
      view.conversation.set({state: 'terminated'});
      // Second call
      view.$('button.initiate-conversation').click();
      secondCallRequest = mostRecentAjaxRequest();
      expect(secondCallRequest.url).toBe('/zestphone/conversations');
    });
  });

  describe("#disableCallControl", function() {
    var view;

    beforeEach(function() {
      setFixtures('<div id="conversation-wrapper" />');
      view = new Zest.Telephony.Views.ConversationView();
      view.render();
      var data = { callingDisabled: true };
      view.disableCallControl(data);
    });

    it("disables the initiate conversation button", function() {
      expect(view.$('button.initiate-conversation')).toBeDisabled();
    });
  });
});
