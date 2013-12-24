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
IWS = 2 if Opt.charge[:ps] || Opt.charge[:eps]
IWS = 4 if Opt.charge[:png]
IWS = 1 if !defined? IWS

# DCL set
clrmp = 14  # カラーマップ
DCL::swlset('lwnd',false) if IWS==4
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

if !Opt.charge[:varname].nil? then
  lonlat(Opt.charge[:varname],list,set_figopt)
else
  lonlat("OSRA",list,"min"=>-1200,"max"=>0,"nlev"=>20,"clr_min"=>99,"clr_max"=>56)
  lonlat("OLRA",list,"min"=>0,"max"=>300,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  lonlat("EvapA",list,"max"=>1000,"clr_min"=>56,"clr_max"=>13)
  lonlat("SensA",list,"max"=>200,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  lonlat("SSRA",list,"min"=>-1000,"max"=>0,"clr_min"=>99,"clr_max"=>56)
  lonlat("SLRA",list,"min"=>0,"max"=>200,"nlev"=>20,"clr_min"=>56,"clr_max"=>13)
  lonlat("Rain",list,"min"=>0,"max"=>1000,"nlev"=>20)
  lonlat("RainCumulus",list,"min"=>0,"max"=>500)
  lonlat("RainLsc",list,"min"=>0,"max"=>500,"nlev"=>20)
  lonlat("SurfTemp",list,"min"=>220,"max"=>360)
  lonlat("Temp",list,"min"=>220,"max"=>320)
  lonlat("RH",list,"min"=>0,"max"=>100)
  lonlat("H2OLiqIntP",list,"min"=>0,"max"=>1,"nlev"=>20)
  lonlat("PrcWtr",list,"min"=>0,"max"=>100,"nlev"=>20)      
  lonlat("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
  lonlat("V",list,"min"=>-10,"max"=>10)      
end  
DCL.grcls
rename_img_file(list,__FILE__)
