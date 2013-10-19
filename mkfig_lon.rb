#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
require 'optparse'
include MKfig
include NumRu


#
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name| VarName = name}
opt.on("-o OPT","--figopt=OPT") {|hash| Figopt = hash}
opt.on("--lat=Lat") {|lat| Lat = lat.to_f}
opt.on("--max=max") {|max| Max = max.to_f}
opt.on("--min=min") {|min| Min = min.to_f}
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
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

if !varname.nil? then
  figopt ={}
  figopt["min"] = Min if defined?(Min) 
  figopt["max"] = Max if defined?(Max) 
  lon_fig(varname,list,figopt)
else
  lon_fig("OSRA",list,"min"=>-1200,"max"=>0)
  lon_fig("OLRA",list,"min"=>0,"max"=>300)
  lon_fig("EvapA",list,"max"=>1000)
  lon_fig("SensA",list,"max"=>200)
  lon_fig("SSRA",list,"min"=>-1000,"max"=>0)
  lon_fig("SLRA",list,"min"=>0,"max"=>200)
  lon_fig("Rain",list,"min"=>0,"max"=>1000)
  lon_fig("RainCumulus",list,"min"=>0,"max"=>1000)
  lon_fig("RainLsc",list,"min"=>0,"max"=>1000)
  lon_fig("SurfTemp",list,"min"=>220,"max"=>360)
  lon_fig("Temp",list,"min"=>220,"max"=>320)
  lon_fig("RH",list,"min"=>0,"max"=>100)
  lon_fig("H2OLiqIntP",list,"min"=>0,"max"=>0.5)
  lon_fig("Albedo",list,"min"=>0,"max"=>1)
  lon_fig("PrcWtr",list,"min"=>0,"max"=>100)      
  lon_fig("U",list,"min"=>-20,"max"=>20)      
  lon_fig("V",list,"min"=>-10,"max"=>10)      
end  
DCL.grcls
rename_img_file(list,__FILE__)
