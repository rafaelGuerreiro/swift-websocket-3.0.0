$(function() {
  "use strict";

  var ws = undefined;
  var error = $("div.error");
  var usernameContainer = $(".center-container.username");
  var chatContainer = $(".center-container.chat");

  var username = usernameContainer.find("input[name=username]").focus();
  var usernameButton = username.siblings(".input-group-btn").children("button");

  var postInput = chatContainer.find("input[name=post]");
  var postButton = postInput.siblings(".input-group-btn").children("button");

  var timeline = chatContainer.find(".timeline");

  (function init() {
    usernameButton.on("click", _usernameReady);
    username.on("keyup", _onEnterHit(_usernameReady));

    $(document).on("click", "*:not(input)", function() {
      $("input:visible:first").focus();
    });
  })();

  function _openConnection(username) {
    var protocols = { "http:": "ws:", "https:": "wss:" };
    try {
      var ws = new WebSocket("ws://localhost:8080/chat/" + username)
//      var ws = new WebSocket([
//         protocols[location.protocol],
//         "//",
//         location.host,
//         "/chat?username=",
//         username,
//         "&sent=",
//         _now()
//       ].join(''));

      window.ws = ws;
      ws.onopen = _socketOpened;
      ws.onmessage = _messageArrived;
      ws.onclose = _socketClosed;
      return ws;
    } catch(e) {
      error.removeClass("hide").text("Unable to connect to the websocket. " + data);
      console.log("Unable to connect to the websocket.", e);
      return undefined;
    }
  }

  function _onEnterHit(fn) {
    return function(e) {
      var key = e.key || e.keyCode || e.which;

      if (key === "Enter" || key === 13) {
        e.preventDefault();
        fn();
      }
    };
  }

  function _usernameReady() {
    if (ws) return;

    var name = username.val();

    if (!name || name.trim().length === 0)
      return;

    ws = _openConnection(name);
  }

  function _submit(e) {
    var value = postInput.val();
    if (!value || value.trim().length === 0)
      return;

    var json = {
      sent: _now(),
      message: value
    };

    var self = { data: $.extend({}, json, { received: _now(), processed: _now() }) };
    _messageArrived(self).addClass("self");

    ws.send(JSON.stringify(json));
    postInput.val("").focus();
  }

  function _socketOpened() {
    postInput.attr("disabled", false)
       .on("keyup", _onEnterHit(_submit));
    postButton.on("click", _submit);

    usernameContainer.addClass("hide");
    chatContainer.removeClass("hide");
    error.addClass("hide").empty();

    postInput.focus();
  }

  function _messageArrived(message) {
    var arrived = _now();
    var data = message.data;

    if (typeof data === "string")
      data = JSON.parse(data);

    var post = $("<div>")
      .addClass("post")
      .attr("sent", data.sent)
      .attr("received", data.received)
      .attr("processed", data.processed)
      .attr("arrived", arrived);

    setTimeout(function() {
      var timestamps = $("<div>").addClass("timestamps alert alert-warning");
      timestamps.append(
        $("<div>").addClass("sent").text("Sent: " + data.sent)
      ).append(
        $("<div>").addClass("received")
          .text("Received: " + data.received + " " + _dateDiff(data.sent, data.received))
      ).append(
        $("<div>").addClass("processed")
          .text("Processed: " + data.processed + " " + _dateDiff(data.received, data.processed))
      ).append(
        $("<div>").addClass("arrived")
          .text("Arrived: " + arrived + " " + _dateDiff(data.processed, arrived))
      ).append(
        $("<div>").addClass("roundtrip")
          .text("Roundtrip: " + _dateDiff(data.sent, arrived))
      ).appendTo(post);
    }, 0);

    post.append($("<div>").addClass("message").text(data.message));

    return post.appendTo(timeline);
  }

  function _socketClosed(data) {
    postInput.attr("disabled", true).off("keyup");

    usernameContainer.removeClass("hide");
    chatContainer.addClass("hide");
    timeline.empty();

    var message = ["Channel closed."];
    if ("code" in data)
      message.push(" Code: " + data.code);
    if ("reason" in data)
      message.push(" Reason: " + data.reason);

    error.removeClass("hide").text(message.join(''));
    console.log(message.join(''), data);

    ws = undefined;
  }

  function _now() {
    return moment().utc().format("YYYY-MM-DDTHH:mm:ss.SSS\\Z");
  }

  function _dateDiff(first, second) {
    first = moment(first, "YYYY-MM-DDTHH:mm:ss.SSS\\Z");
    second = moment(second, "YYYY-MM-DDTHH:mm:ss.SSS\\Z");

    return ["(", second.diff(first), " ms)"].join('');
  }
});
