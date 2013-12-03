#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 実験シリーズの偏差
# A-C, A-D
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math


def fig_lonlat_diff(var_name,lists,hash={})
  all = Omega::Anomaly.new(var_name,lists[:all])
  diurnal = Omega::Anomaly.new(var_name,lists[:diurnal])
  coriolis = Omega::Anomaly.new(var_name,lists[:coriolis])
  del_ad = all.minus(diurnal)
  del_ac = all.minus(coriolis)
  Omega.lonlat2(del_ad.anomaly,lists[:diurnal],{"add"=>"A-D "}.merge(hash))
  Omega.lonlat2(del_ac.anomaly,lists[:coriolis],{"add"=>"A-C "}.merge(hash))
end

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
opt.parse!(ARGV)

# DCL set
IWS = 1 if !defined?(IWS)
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(0.8)

a_list = "/home/ishioka/link/all/fig/list/omega_all_MTlocal.list"
d_list = "/home/ishioka/link/diurnal/fig/list/omega_diurnal_MTlocal.list"
c_list = "/home/ishioka/link/coriolis/fig/list/omega_coriolis_MTlocal.list"
lists={
  all:      Utiles_spe::Explist.new(a_list),
  diurnal:  Utiles_spe::Explist.new(d_list),
  coriolis: Utiles_spe::Explist.new(c_list)
}

fig_lonlat_diff("OSRA",lists,"min"=>-250,"max"=>250,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_diff("OLRA",lists,"min"=>-100,"max"=>100,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_diff("EvapA",lists,"min"=>-150,"max"=>150,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_diff("SensA",lists,"min"=>-100,"max"=>100,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_diff("SSRA",lists,"min"=>-200,"max"=>200,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_diff("SLRA",lists,"min"=>-60,"max"=>60,"nlev"=>12,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_diff("Rain",lists,"min"=>-800,"max"=>800,"nlev"=>16)
fig_lonlat_diff("RainCumulus",lists,"min"=>-500,"max"=>500,"nlev"=>20)
fig_lonlat_diff("RainLsc",lists,"min"=>-500,"max"=>500,"nlev"=>20)
fig_lonlat_diff("SurfTemp",lists,"min"=>-30,"max"=>30,"nlev"=>12)
fig_lonlat_diff("Temp",lists,"min"=>-20,"max"=>20)
fig_lonlat_diff("QVap",lists,"min"=>0,"max"=>0.01)
fig_lonlat_diff("RH",lists,"min"=>-50,"max"=>50)
fig_lonlat_diff("H2OLiqIntP",lists,"min"=>-1,"max"=>1)
fig_lonlat_diff("PrcWtr",lists,"min"=>-50,"max"=>50,"nlev"=>20)      
fig_lonlat_diff("U",lists,"min"=>-20,"max"=>20,"nlev"=>20)      
fig_lonlat_diff("V",lists,"min"=>-10,"max"=>10)      

DCL.grcls
rename_img_file("omega",__FILE__)
