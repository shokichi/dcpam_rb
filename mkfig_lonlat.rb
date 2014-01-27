#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/make_figure.rb")
include MKfig
include NumRu


# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set

list = Utiles_spe::Explist.new(ARGV[0])
IWS = get_iws
set_dcl(14)

FigType = "lonlat"
if !Opt.charge[:name].nil? then
  make_figure(Opt.charge[:name],list,set_figopt)
else
  make_figure("OSRA",list,"min"=>-1200,"max"=>0,"nlev"=>20,"clr_min"=>99,"clr_max"=>56)
  make_figure("OLRA",list,"min"=>0,"max"=>300,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  make_figure("EvapA",list,"max"=>1000,"clr_min"=>56,"clr_max"=>13)
  make_figure("SensA",list,"max"=>200,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  make_figure("SSRA",list,"min"=>-1000,"max"=>0,"clr_min"=>99,"clr_max"=>56)
  make_figure("SLRA",list,"min"=>0,"max"=>200,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  make_figure("Rain",list,"min"=>0,"max"=>1000,"nlev"=>20)
  make_figure("RainCumulus",list,"min"=>0,"max"=>500)
  make_figure("RainLsc",list,"min"=>0,"max"=>500,"nlev"=>20)
  make_figure("SurfTemp",list,"min"=>220,"max"=>360)
  make_figure("Temp",list,"min"=>220,"max"=>320)
  make_figure("RH",list,"min"=>0,"max"=>100)
  make_figure("H2OLiqIntP",list,"min"=>0,"max"=>1,"nlev"=>20)
  make_figure("PrcWtr",list,"min"=>0,"max"=>100,"nlev"=>20)      
  make_figure("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
  make_figure("V",list,"min"=>-10,"max"=>10)      
end  
DCL.grcls
rename_img_file(list,__FILE__)
