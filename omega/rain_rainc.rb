#!/usr/bin/env ruby
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

def rain_rainc(dir)
  rain = gpopen dir + "Rain.nc"
  rainc = gpopen dir + "RainCumulus.nc"
  
  return rainc/rain  
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
list.dir.each{|dir| data << rain_rainc(dir)}
Omega.lat_fig2(data,list,"min"=>0,"max"=>1)
Omega.lonlat2(data,list,"min"=>0,"max"=>1)

DCL.grcls
rename_img_file(list,__FILE__)
