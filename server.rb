require "socket"
require "open-uri"

require "sinatra"
require "sinatra/reloader" if development?
require "vmstat"
require "slim"
require "sass"

@cpu_temp = 0.0
@network_usage = 0.0
$last_total= 0.0
$remote_ip = open('http://whatismyip.akamai.com').read

def check_temp
  temp = `sensors -f | grep 'Core'`
  _temp= 0
  temp.split("\n").each {|t| _t = t.split(':')[1].strip.to_f; if _t > _temp; _temp = _t;end}

  _temp
end

def get_network_load(vmstat)
  number           = ((vmstat.network_interfaces.last.in_bytes+vmstat.network_interfaces.last.out_bytes)/1000.0)*8.round(2)
  puts "#{$last_total} | #{number}"
  puts "#{@last_total} | #{number}"
  $last_total = number-$last_total

  @network_usage = $last_total

  return @network_usage
end

get "/" do
  @hostname = Socket.gethostname
  @local_ip = "192.168.1.???"
  @remote_ip= "192.168.1.???"
  @vmstat   = Vmstat.snapshot
  @cpu_temp = check_temp
  @network_usage = @network_usage
  get_network_load(@vmstat)
  slim :index
end

get "/css/app.css" do
  sass :application
end
