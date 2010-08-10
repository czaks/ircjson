ircjson = {
  host: "http://6irc.net/api/6ircremote-1.0/",
  apikey: "BETAKEY",
  
  version: "0.1.1",
  mirror: null,
  
  connid: null,
  
  loadjs: function(url) {
    tag = document.createElement("script");
    tag.src = url;
    tag.type = "text/javascript";
    document.getElementsByTagName("head")[0].appendChild(tag);
  },
  
  init: function() {
    this.loadjs(this.host);
  },
  
  mirror_found: function(a) {
    this.mirror = a;
    this.loadjs(this.mirror+"*/create_session?apikey="+this.apikey+"&version="+this.version+"&nocache="+Math.random());
  },
  
  poll: function() {
    this.loadjs(this.mirror+this.connid+"/poll?nocache="+Math.random());
  },
  
  send: function(a) {
    this.loadjs(this.mirror+this.connid+"/send?line="+encodeURIComponent(a)+"&nocache="+Math.random());
  },
  
  handle: function(a) {
    if (typeof a.connid != "undefined") {
      this.connid = a.connid;
    }
    
    if (typeof a.replies != "undefined") {
      for (i in a.replies) {
        this.onReply(a.replies[i]);
      }
      this.onGotReplies();
    }
    else if (typeof a.error != "undefined") {
      this.onError(a.error);
    }
    else {
      this.onConnect();
    }
  },
  
  onConnect: function() {
  },
  onReply: function(a) {
  },
  onGotReplies: function() {
  },
  onError: function(a) {
    alert("ircjson error: "+a);
  }
}
ircjson_mirror_found = function(a) { ircjson.mirror_found(a); }
ircjson_handle = function(a) { ircjson.handle(a); }
