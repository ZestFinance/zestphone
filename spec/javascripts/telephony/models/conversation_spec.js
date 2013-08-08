describe("Zest.Telephony.Models.Conversation", function() {
  var conversation;

  beforeEach(function() {
    conversation = new Zest.Telephony.Models.Conversation();
  });

  describe("#url", function() {
    it("uses the correct path", function() {
      var convo = new Zest.Telephony.Models.Conversation();
      expect(convo.url()).toEqual('/zestphone/conversations');
    });
  });

  describe("#create", function() {
    describe("when succeeds", function() {
      it("creates a conversation remotely", function() {
        jasmine.Ajax.useMock();

        var convo = new Zest.Telephony.Models.Conversation();
        spyOn(convo, 'createSuccess');
        convo.set({
          loanId: '123',
          to: "3003004002",
          toId: '9',
          toType: 'borrower',
          from: "3003004000",
          fromId: '1'
        });
        convo.create();

        var request = mostRecentAjaxRequest();
        var response = { id: 100, caller_call_id: 200, callee_call_id: 201 };
        request.response({status: 200, responseText: JSON.stringify(response)});

        expect(convo.createSuccess).toHaveBeenCalled();
        expect(request.method).toEqual('POST');
        var data = {
          loan_id: '123',
          from: '3003004000',
          from_id: '1',
          from_type: 'csr',
          to: '3003004002',
          to_id: '9',
          to_type: 'borrower'
        };
        expect(request.params).toEqual($.param(data));
      });
    });

    describe("when fails", function() {
      var failHandler;

      beforeEach(function() {
        failHandler = jasmine.createSpy('fail');
        $(document).bind('callFailed', failHandler);
      });

      it("returns an error message", function() {
        jasmine.Ajax.useMock();

        var convo = new Zest.Telephony.Models.Conversation();
        convo.create();

        var request = mostRecentAjaxRequest();
        var response = { errors: ['some error'] };
        request.response({status: 500, responseText: JSON.stringify(response)});

        expect(failHandler).toHaveBeenCalled();
        expect(failHandler.mostRecentCall.args[1]).toEqual('some error');
      });
    });
  });

  describe('#hold', function() {
    it("changes state to 'initiating_hold'", function() {
      jasmine.Ajax.useMock();

      conversation.hold();
      expect(conversation.get('state')).toEqual('initiating_hold');
    });
  });

  describe('#resume', function() {
    it("changes state to 'initiating_resume'", function() {
      jasmine.Ajax.useMock();

      conversation.resume();
      expect(conversation.get('state')).toEqual('initiating_resume');
    });
  });

  describe('#uiDisableCall', function() {
    describe('given a new conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'not_initiated' });
      });

      it('enables the button', function() {
        expect(conversation.uiDisableCall()).toEqual('');
      });
    });

    describe('given a terminated conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'terminated' });
      });

      it('returns true', function() {
        expect(conversation.uiDisableCall()).toEqual('');
      });
    });

    describe('given a conversation in progress', function() {
      beforeEach(function() {
        conversation.set({ state: 'in_progress' });
      });

      it('disables the call controls', function() {
        expect(conversation.uiDisableCall()).toEqual('disabled');
      });
    });

    describe('given a conversation with calling disabled', function() {
      beforeEach(function() {
        conversation.set({ callingDisabled: true });
      });

      it('disables the call controls', function() {
        expect(conversation.uiDisableCall()).toEqual('disabled');
      });
    });
  });

  describe('#uiShowCall', function() {
    describe('given a new conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'not_initiated' });
      });

      it('returns true', function() {
        expect(conversation.uiShowCall()).toEqual('');
      });
    });

    describe('given a connecting conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'connecting' });
      });

      it('returns true', function() {
        expect(conversation.uiShowCall()).toEqual('');
      });
    });

    describe('given a terminated conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'terminated' });
      });

      it('returns true', function() {
        expect(conversation.uiShowCall()).toEqual('');
      });
    });

    describe('given a conversation in progress', function() {
      beforeEach(function() {
        conversation.set({ state: 'in_progress' });
      });

      it('hides the button', function() {
        expect(conversation.uiShowCall()).toEqual('hidden');
      });
    });
  });

  describe("#uiShowHold", function() {
    describe("given the 'in_progress' coversation", function() {
      it("shows the hold button", function() {
        conversation.set({state: "in_progress"});

        expect(conversation.uiShowHold()).toEqual("");
      });
    });

    describe("given the 'in_progress_two_step_transfer' coversation", function() {
      it("shows the hold button", function() {
        conversation.set({state: "in_progress_two_step_transfer"});

        expect(conversation.uiShowHold()).toEqual("");
      });
    });

    describe("given the 'initiating_hold' coversation", function() {
      it("shows the hold button", function() {
        conversation.set({state: "initiating_hold"});

        expect(conversation.uiShowHold()).toEqual("");
      });
    });
  });

  describe('#uiDisableTransfer', function() {
    describe('given an in progress conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'in_progress' });
      });

      it('enables the button', function() {
        expect(conversation.uiDisableTransfer()).toEqual('');
      });
    });

    describe('given an "initiating_hold" conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'initiating_hold' });
      });

      it('disables the button', function() {
        expect(conversation.uiDisableTransfer()).toEqual('disabled');
      });
    });

    describe('given a "on-hold" conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'in_progress_hold' });
      });

      it('enables the button', function() {
        expect(conversation.uiDisableTransfer()).toEqual('');
      });
    });

    describe('given a "initiating_resume" conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'initiating_resume' });
      });

      it('disables the button', function() {
        expect(conversation.uiDisableTransfer()).toEqual('disabled');
      });
    });

    describe('given a not in progress conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'connecting'});
      });

      it('returns true', function() {
        expect(conversation.uiDisableTransfer()).toEqual('disabled');
      });
    });
  });

  describe('#uiShowTransfer', function() {
    describe('given a cancelable conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'in_progress', isCancelable: true });
      });

      it('hides the button', function() {
        expect(conversation.uiShowTransfer()).toEqual('hidden');
      });
    });

    describe('given a transferable conversation', function() {
      var displayableStates;

      beforeEach(function() {
        displayableStates = ['in_progress', 'one_step_transferring',
          'in_progress_hold', 'two_step_transferring', 'in_progress_two_step_transfer',
          'initiating_hold', 'initiating_resume'];
      });

      it('shows the button', function() {
        _.each(displayableStates, function(state) {
          conversation.set({ state: state });
          expect(conversation.uiShowTransfer()).toEqual('');
        });
      });
    });

    describe('given a non-transferable conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'connecting'});
      });

      it('hides the button', function() {
        expect(conversation.uiShowTransfer()).toEqual('hidden');
      });
    });
  });

  describe("#uiDisableResume", function() {
    describe("given an 'initiating_resume' conversation", function() {
      it("disables the button", function() {
        conversation.set({state: 'initiating_resume', owner: true});

        expect(conversation.uiDisableResume()).toEqual("disabled");
      });
    });

    describe("given an 'in_progress' conversation", function() {
      describe("for the conversation owner", function() {
        it("enables the button", function() {
          conversation.set({state: 'in_progress', owner: true});

          expect(conversation.uiDisableResume()).toEqual("");
        });
      });

      describe("for the conversation non-owner", function() {
        it("disables the button", function() {
          conversation.set({state: 'in_progress', owner: false});

          expect(conversation.uiDisableResume()).toEqual("disabled");
        });
      });
    });
  });

  describe("#uiDisableHold", function() {
    describe("given an 'initiating_hold' conversation", function() {
      it("disables the button", function() {
        conversation.set({state: 'initiating_hold', owner: true});

        expect(conversation.uiDisableHold()).toEqual("disabled");
      });
    });

    describe("given an 'in_progress' conversation", function() {
      describe("for the conversation owner", function() {
        it("enables the button", function() {
          conversation.set({state: 'in_progress', owner: true});

          expect(conversation.uiDisableHold()).toEqual("");
        });
      });

      describe("for the conversation non-owner", function() {
        it("disables the button", function() {
          conversation.set({state: 'in_progress', owner: false});

          expect(conversation.uiDisableHold()).toEqual("disabled");
        });
      });
    });
  });

  describe("#uiShowResume", function() {
    describe("given an 'in_progress_hold' conversation", function() {
      it("shows the button", function() {
        conversation.set({state: 'in_progress_hold'});

        expect(conversation.uiShowResume()).toEqual("");
      });
    });

    describe("given an 'initiating_resume' conversation", function() {
      it("shows the button", function() {
        conversation.set({state: 'initiating_resume'});

        expect(conversation.uiShowResume()).toEqual("");
      });
    });

    describe("given an 'in_progress' conversation", function() {
      it("hides the button", function() {
        conversation.set({state: 'in_progress'});

        expect(conversation.uiShowResume()).toEqual("hidden");
      });
    });
  });

  describe('#uiShowCancelTransfer', function() {
    describe('given a cancelable conversation', function() {
      beforeEach(function() {
        conversation.set({ isCancelable: true });
      });

      it('returns true', function() {
        expect(conversation.uiShowCancelTransfer()).toEqual('');
      });
    });

    describe('given a not-cancelable conversation', function() {
      beforeEach(function() {
        conversation.set({ isCancelable: false });
      });

      it('hides the button', function() {
        expect(conversation.uiShowCancelTransfer()).toEqual('hidden');
      });
    });
  });

  describe('#uiShowCallSpinner', function() {
    describe('given a connecting conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'connecting' });
      });

      it('returns true', function() {
        expect(conversation.uiShowCallSpinner()).toEqual('display');
      });
    });

    describe('given a not-connecting conversation', function() {
      beforeEach(function() {
        conversation.set({ state: 'in_progress' });
      });

      it('shows the button', function() {
        expect(conversation.uiShowCallSpinner()).toEqual('');
      });
    });
  });

  describe("#uiShowHoldSpinner", function() {
    describe("given 'intiating_hold' conversation", function() {
      it("shows the spinner", function() {
        conversation.set({ state: 'initiating_hold' });

        expect(conversation.uiShowHoldSpinner()).toEqual('display');
      });
    });

    describe("given an 'in_progress' conversation", function() {
      it("doesn't show the spinner", function() {
        conversation.set({ state: 'in_progress' });

        expect(conversation.uiShowHoldSpinner()).toEqual('');
      });
    });
  });

  describe("#uiShowResumeSpinner", function() {
    describe("given 'intiating_resume' conversation", function() {
      it("shows the spinner", function() {
        conversation.set({ state: 'initiating_resume' });

        expect(conversation.uiShowResumeSpinner()).toEqual('display');
      });
    });

    describe("given an 'in_progress' conversation", function() {
      it("doesn't show the spinner", function() {
        conversation.set({ state: 'in_progress' });

        expect(conversation.uiShowResumeSpinner()).toEqual('');
      });
    });
  });

  describe('#isValid', function() {
    var conversation;

    describe('given a conversation with a valid phone number', function() {
      var validPhoneNumbers;

      beforeEach(function() {
        validPhoneNumbers = ['555-111-1111', '+1 222-222-2222'];
      });

      it('returns true', function() {
        _.each(validPhoneNumbers, function(phoneNumber) {
          conversation = new Zest.Telephony.Models.Conversation({
            from: '222-333-4444',
            to: phoneNumber
          });
          expect(conversation.isValid()).toBeTruthy(phoneNumber + ' is not valid');
        });
      });
    });

    describe('given a conversation with an invalid phone number', function() {
      var invalidPhoneNumbers;

      beforeEach(function() {
        invalidPhoneNumbers = [null, '', 111, '(111)', '111-111-1111', '+2 333-333-3333'];
      });

      it('returns false', function() {
        _.each(invalidPhoneNumbers, function(phoneNumber) {
          conversation = new Zest.Telephony.Models.Conversation({
            from: '222-333-4444',
            to: phoneNumber
          });
          expect(conversation.isValid()).toBeFalsy(phoneNumber + ' is valid');
          expect(conversation.errorMessage).toEqual('Please enter a 10-digit phone number');
        });
      });
    });

    describe('given a conversation from and to the same number', function() {
      var agentNumber;

      beforeEach(function() {
        agentNumber = '222-333-4444';
      });

      it('returns false', function() {
        _.each(['222-333-4444', '2223334444', '(222) 333-4444'], function(callee) {
          conversation = new Zest.Telephony.Models.Conversation({
            from: agentNumber,
            to: callee
          });
          expect(conversation.isValid()).toBeFalsy();
          expect(conversation.errorMessage).toEqual('Please input a customer phone number');
        });
      });
    });
  });
});
