require "socket"
require "open-uri"
require "ostruct"

require "sinatra"
# require "sinatra/reloader" if development?
require "vmstat"
require "slim"
require "sass"

Keystore = OpenStruct.new
Keystore.last_net_in  = 0.0
Keystore.last_net_out = 0.0
Keystore.total_net    = 0.0
Keystore.net_interface= "eth0"
Keystore.remote_ip    = ""

Keystore.ram_percentage = 0.0
Keystore.ram_usage = 0.0
Keystore.uptime = "0"

# `export PATH="$PATH:/sbin"`

def check_temp
  temp = `sensors -f | grep 'Core'`
  _temp= 0
  temp.split("\n").each {|t| _t = t.split(':')[1].strip.to_f; if _t > _temp; _temp = _t;end}

  _temp
end

def calc_network_load
  network_usage = `ifconfig #{Keystore.network_interface} | grep "TX bytes"`
  list = network_usage.split(":")
  Keystore.net_in  = list[1].split(" ").first.to_i
  Keystore.net_out = list[3].split(" ").first.to_i

  _in = Keystore.net_in  - Keystore.last_net_in
  _out= Keystore.net_out - Keystore.last_net_out

  Keystore.last_net_in  = Keystore.net_in
  Keystore.last_net_out = Keystore.net_out

  Keystore.total_net = _in+_out
end

def get_ram_usage
  free = 0
  total= 0
  percent = 0.0
  file = File.open("/proc/meminfo").each_with_index do |line, i|
    case i
    when 0
      total = line.split(":").last.split(" ").first.strip.to_f/1000.0
    when 1
      # free += line.split(":").last.split(" ").first.strip.to_f/1000.0
    when 2
      free = line.split(":").last.split(" ").first.strip.to_f/1000.0
    end
  end

  n = total-free
  Keystore.ram_percentage = n/total*100.0

  Keystore.ram_usage = "#{free.round(2)}MB / #{(total/1000.0).round(2)}GB"
end

def system_uptime(vmstat)
  uptime = ((vmstat.at-vmstat.boot_time)/60/60)
  string = ""
  case
  when uptime <= 23.9
    string = "#{uptime} Hours"
  when uptime > 23.9
    string = "#{(uptime/24).round(2)} Days"
  end

  Keystore.uptime = string
end

Thread.new do
  loop do
    calc_network_load
    sleep 1
  end
end

Thread.new { loop {Keystore.remote_ip = open('http://whatismyip.akamai.com').read; sleep 10*60}}

get "/" do
  get_ram_usage
  @hostname = Socket.gethostname
  @local_ip = "192.168.1.???"
  @remote_ip= "192.168.1.???"
  @vmstat   = Vmstat.snapshot
  system_uptime(@vmstat)
  @cpu_temp = check_temp
  @network_usage = Keystore.total_net
  slim :index
end

get "/css/app.css" do
  sass :application
end

