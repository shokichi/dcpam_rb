#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# H2Oの鉛直積分
#

require 'numru/ggraph'
require 'numru/gphys'
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu
include Math

def intg_h2o(dir)
  h2o = gpopen dir+"H2OLiq.nc"
  ps = gpopen dir+"Ps.nc"
  sig_weight = gpopen dir+"H2OLiq.nc", "sig_weight"
  return if h2o.nil? or ps.nil? or sig_weight.nil?
 
  data_name = "H2OLiqIntP"
  ofile = NetCDF.create(dir + data_name + '.nc')
  GPhys::NetCDF_IO.each_along_dims_write([h2o,ps], ofile,'time') { 
    |liq,gps|
    result = (liq * gps * sig_weight).sum("sig")/Grav
    result.name = data_name
    [result]
  }
  ofile.close
  print "[#{data_name}](#{dir}) is created \n"
  
end


opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.parse!(ARGV)

Utiles_spe::Explist.new(ARGV[0]).dir.each{
  |dir| 
  intg_h2o(dir)
}
