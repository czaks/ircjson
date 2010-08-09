#\ -o :: -p 6680
# Copyright (c) 2010 Marcin Łabanowski
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require "socket"        #TCPSocket
require "json"          #JSON.generate
require "cgi"           #CGI::unescape
require "resolv"        #Resolv.getname

IDENT = "ircjson"
REALNAME = "6ircremote-1.0"
HOST, PORT = "sundance.6irc.net", 6667
WEBIRC_PASSWORD = nil

APIKEYS = {
  "BETAKEY" => //
}

class IRCConnection
  attr_accessor :fp, :apikey
  
  def initialize host, port, remote_addr=""
    @fp = TCPSocket.new(host, port)
    @tmp = ""
    @remote_addr = remote_addr.sub(/^::ffff:/,"")
    begin
      @remote_host = Resolv.getname @remote_addr
    rescue Exception
      @remote_host = @remote_addr
    end
  end
  
  def sendline line
    line = line.gsub(/[\r\n]/, "").chomp
    cmd,rest = line.split(" ", 2)
    cmd = cmd.strip
    rest = rest ? rest : ""
    begin
      case cmd
      when "6IN:USER"
        rest = rest.split(" ", 2)
        fp.puts "WEBIRC #{WEBIRC_PASSWORD} ircjson #@remote_host #@remote_addr" if WEBIRC_PASSWORD
        fp.puts "USER #{IDENT} 0 0 :#{REALNAME}"
        fp.puts "NICK :#{rest[0]}"
        fp.puts "PASS :#{rest[1]}" if rest[1]
      when "USER"
      when "PASS"
      else
        fp.puts line
      end
      true
    rescue Exception
      false
    end
  end
  
  def getlines
    begin
      ary = []
      data = fp.recv_nonblock(15000)
      if data == ""
        raise "Something gone wrong"
      end
      data = @tmp + data
      loop do
        cur, data = data.split("\n", 2)
        if cur == nil
          break
        end
        cur.chomp!
        ary << cur
        if data == nil
          @tmp = data
          break
        end
      end
      ary
    rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      []
    rescue Exception
      nil
    end
  end
end

def random_string(length=8)
  k = ""
  length.times do
    k << (?a + rand(26))
  end
  k
end

$conns = {}

use Rack::ContentLength
app = proc do |env|
  path=CGI::unescape env["PATH_INFO"]
  params=Hash[*(env["QUERY_STRING"].split("&").map { |i| CGI::unescape(i).split("=") }.flatten)]
  referer=env["HTTP_REFERER"]
  
  pathfrags = path.split("/")
  pathfrags.shift
  
  data = {}
  
  loop do #i just want to be able to break at the arbitrary time
    case pathfrags[0]
    when "*" #not logged in
      case pathfrags[1]
      when "create_session"
        if APIKEYS[params["apikey"]] and (APIKEYS[params["apikey"]] =~ referer)
          connid = random_string(12)
          data["connid"] = connid
          $conns[connid] = IRCConnection.new(HOST, PORT, env["REMOTE_ADDR"])
          $conns[connid].apikey = params["apikey"]
        else
          data["error"] = "Wrong API key"
        end
      else
        data["error"] = "Unknown entity"
      end
    else #logged in, let's check out if really
      connid = pathfrags[0]
      if $conns[connid] == nil
        data["error"] = "Not logged in"
        break
      end
      
      data["connid"] = connid
      
      if !APIKEYS[$conns[connid].apikey] or !(APIKEYS[$conns[connid].apikey] =~ referer)
        data["error"] = "Wrong API key"
        break
      end
      
      case pathfrags[1]
      when "send"
        $conns[connid].sendline(params["line"])
      when "poll"
      else
        data["error"] = "Unknown entity"
        break
      end
      
      lines = $conns[connid].getlines
      if lines
        data["replies"] = lines
      else
        data["error"] = "Disconnected"
        begin
          $conns.delete(connid).fp.close
        rescue Exception
        end
      end
    end
    break
  end
  
  [200, {"Content-type" => "text/javascript"}, "ircjson_handle(#{JSON.generate data});\n"]
end

run app
