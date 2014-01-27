#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/lib/dcpam.rb")
include MKfig
include NumRu


def fig_anomaly(varname,list,opt)
  gpa = GPhysArray.new(varname,list)
  gpa = gpa.anomaly
  lonlat(gpa,opt)
end

# option
Opt = OptCharge::OptCharge.new(ARGV)
Opt.set
list = Utiles_spe::Explist.new(ARGV[0])

IWS = get_iws

# DCL set
set_dcl(14)

FigType = "lonlat"
if !Opt.charge[:name].nil?
  fig_anomaly(Opt.charge[:name],list,set_figopt)
else
  fig_anomaly("OSRA",list,"min"=>-250,"max"=>250,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
  fig_anomaly("OLRA",list,"min"=>-100,"max"=>100,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
  fig_anomaly("EvapA",list,"min"=>-150,"max"=>150,"clr_min"=>99,"clr_max"=>13)
  fig_anomaly("SensA",list,"min"=>-100,"max"=>100,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
  fig_anomaly("SSRA",list,"min"=>-200,"max"=>200,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
  fig_anomaly("SLRA",list,"min"=>-60,"max"=>60,"nlev"=>12,"clr_min"=>99,"clr_max"=>13)
  fig_anomaly("Rain",list,"min"=>-800,"max"=>800,"nlev"=>16)
  fig_anomaly("RainCumulus",list,"min"=>-500,"max"=>500,"nlev"=>20)
  fig_anomaly("RainLsc",list,"min"=>-500,"max"=>500,"nlev"=>20)
  fig_anomaly("SurfTemp",list,"min"=>-30,"max"=>30,"nlev"=>12)
  fig_anomaly("Temp",list,"min"=>-20,"max"=>20)
  fig_anomaly("RH",list,"min"=>-50,"max"=>50)
  fig_anomaly("H2OLiqIntP",list,"min"=>-0.1,"max"=>0.1)
  fig_anomaly("PrcWtr",list,"min"=>-50,"max"=>50,"nlev"=>20)      
  fig_anomaly("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
  fig_anomaly("V",list,"min"=>-10,"max"=>10)      
end
DCL.grcls

rename_img_file(list,__FILE__)
