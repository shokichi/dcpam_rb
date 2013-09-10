#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
#
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math

def rain_evap(dir)
  rain = gpopen dir + "Rain.nc"
  evap = gpopen dir + "EvapA.nc"
  result = evap - rain 
  return result
end
# ---------------------------------------



opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}

opt.parse!(ARGV)
varname = VarName if defined?(VarName)
list = Utiles_spe::Explist.new(ARGV[0])
IWS = 1 if !defined?(IWS) or IWS.nil?

# DCL set
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

list = Utiles_spe::Explist.new(ARGV[0])
data = []
list.dir.each{|dir| data << rain_evap(dir)}
Omega.lat_fig2(data,list,"min"=>-300,"max"=>300)
Omega.lonlat2(data,list,"min"=>-300,"max"=>300)

DCL.grcls
rename_img_file(list,__FILE__)
