Zest.Telephony.Views.AgentsView = Backbone.View.extend({
  template: JST["templates/telephony/agents_view"],

  events: {
    "click li": "setSelectedAgent"
  },

  initialize: function(options) {
    this.currentAgentId = options.currentAgentId;

    if (options.agents) {
      this.agents = options.agents;
    } else {
      this.agents = new Zest.Telephony.Collections.Agents();
      this.agents.fetch({data: {csr_id: this.currentAgentId}});
    }
    this.agents.bind("reset", this.render, this);
  },

  filter: function(query) {
    if (!this.allAgentsJSON) {
      this.allAgentsJSON = this.agents.toJSON();
    }

    if (query === "") {
      this.agents.reset(this.allAgentsJSON);
    } else {
      var matchedAgents = _.filter(this.allAgentsJSON, function(agent) {
        var agentString = agent.csr_type + ' ' +
          agent.name + ' ' + agent.phone_ext;
        var queries = _.map(query.split(' '), function(str){
          return str.trim();
        });

        return _.reduce(queries, function(memo, qry) {
          var regex = new RegExp(qry, 'i');
          return memo && regex.test(agentString);
        }, true);
      });

      this.agents.reset(matchedAgents);
    }
  },

  selectBestMatched: function() {
    var firstAgent = this.agents.at(0);
    this.triggerAgentSelection(firstAgent);
  },

  triggerAgentSelection: function(selectedAgent) {
    $(this.el).trigger("agentDidSelect", selectedAgent);
  },

  setSelectedAgent: function(evt) {
    var agentId = $(evt.currentTarget).data("id");
    var selectedAgent = this.agents.get(agentId);
    this.triggerAgentSelection(selectedAgent);
  },

  render: function () {
    var that = this;
    var filteredAgents = this.agents.filter(function (agent) {
      return !(agent.get("csr_id") == that.currentAgentId);
    });
    this.agents.reset(filteredAgents, {silent: true});
    var html = this.template({agents: this.agents});
    this.el.html(html);
  }
});
