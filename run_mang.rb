#!/usr/bin/ruby
#
#

require 'optparse'
opt = OptionParser.new
opt.on("-w VAL","--wait=VAL") {|wait| WAIT= wait.to_i}
opt.on("-c CMD","--cmd=CMD") {|cmd| CMD = cmd.to_s}
opt.parse!(ARGV)

if defined?(WAIT) and !WAIT.nil? and WAIT!=0
  wait = WAIT
else
  wait = 10
end

if defined?(CMD) and !CMD.nil?
  cmd = CMD
else
  cmd = "dcpam" 
end

loop{
  if !`ps -A | grep #{cmd}`.include?(cmd)  then
    `nohup ./run.sh &`
    print "Start run.sh [#{Time.now}]\n"
    break
  end
  sleep wait*60
}
