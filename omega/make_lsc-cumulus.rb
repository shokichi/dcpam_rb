#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 
#

require 'numru/ggraph'
require 'numru/gphys'
require '/home/ishioka/ruby/dcpam_rb/lib/utiles_spe'
require 'optparse'
include Utiles_spe
include NumRu
include Math

def create_RainLsc(dir)
  data_name = "RainLsc"
  dir += PRF if defined?(PRF)
  begin
    gp = GPhys::IO.open(dir + 'DQVapDtLsc.nc',"DQVapDtLsc")
    ps = GPhys::IO.open(dir + 'Ps.nc',"Ps")
#  sig_weight = GPhys::IO.open(dir + 'DQVapDtLsc.nc',"sig_weight")
    sig_weight = GPhys::IO.open('/home/ishioka/link/all/omega1/data/DQVapDtCumulus.nc',"sig_weight")
  rescue
    puts "No such file"
    return
  end
  result = -LatentHeat * (gp * ps * sig_weight).sum("sig")/Grav
  result.name = data_name
  result.units = "W.m-2"
  ofile = NetCDF.create(dir + data_name + '.nc')
  GPhys::IO.write(ofile, result)
  ofile.close
  print "[#{data_name}](#{dir}) is created\n"
end

def create_RainCumulus(dir)
  data_name = "RainCumulus"
  dir += PRF if defined?(PRF)
  begin
    gp = GPhys::IO.open(dir + 'DQVapDtCumulus.nc','DQVapDtCumulus')
    ps = GPhys::IO.open(dir + 'Ps.nc',"Ps")
    sig_weight = GPhys::IO.open('/home/ishioka/link/all/omega1/data/DQVapDtCumulus.nc',"sig_weight")
  rescue
    puts "No such file"
    return
  end

  result = -LatentHeat * (gp * ps * sig_weight).sum("sig")/Grav
  result.name = data_name
  result.units = "W.m-2"
  ofile = NetCDF.create(dir + data_name + '.nc')
  GPhys::IO.write(ofile, result)
  ofile.close
  print "[#{data_name}](#{dir}) is created\n"
end

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--prefix=STR") {|str| PRF = str}
opt.parse!(ARGV)

list = Utiles_spe::Explist.new(ARGV[0])
list.dir.each{|dir| create_RainLsc(dir)}
list.dir.each{|dir| create_RainCumulus(dir)}

