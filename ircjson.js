/* Copyright (c) 2010 Marcin Łabanowski
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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
