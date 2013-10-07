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


def fig_lonlat_anml(var_name,lists,hash={})
  all = Omega::Anomaly.new(var_name,lists[:all])
  diurnal = Omega::Anomaly.new(var_name,lists[:diurnal])
  coriolis = Omega::Anomaly.new(var_name,lists[:coriolis])
  Omega.lonlat2(all.anomaly,lists[:all],{"add"=>"A "}.merge(hash))
  Omega.lonlat2(diurnal.anomaly,lists[:diurnal],{"add"=>"D "}.merge(hash))
  Omega.lonlat2(coriolis.anomaly,lists[:coriolis],{"add"=>"C "}.merge(hash))
  plus_dc = diurnal.plus(coriolis)
  del_adc = all.minus(plus_dc)
  Omega.lonlat2(plus_dc.anomaly,lists[:diurnal],{"add"=>"C+D "}.merge(hash))
  Omega.lonlat2(del_adc.anomaly,lists[:all],{"add"=>"A-D-C "}.merge(hash))
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

fig_lonlat_anml("OSRA",lists,"min"=>-250,"max"=>250,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_anml("OLRA",lists,"min"=>-100,"max"=>100,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_anml("EvapA",lists,"min"=>-150,"max"=>150,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_anml("SensA",lists,"min"=>-100,"max"=>100,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_anml("SSRA",lists,"min"=>-200,"max"=>200,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_anml("SLRA",lists,"min"=>-60,"max"=>60,"nlev"=>12,"clr_min"=>99,"clr_max"=>13)
fig_lonlat_anml("Rain",lists,"min"=>-800,"max"=>800,"nlev"=>16)
fig_lonlat_anml("RainCumulus",lists,"min"=>-500,"max"=>500,"nlev"=>20)
fig_lonlat_anml("RainLsc",lists,"min"=>-500,"max"=>500,"nlev"=>20)
fig_lonlat_anml("SurfTemp",lists,"min"=>-30,"max"=>30,"nlev"=>12)
fig_lonlat_anml("Temp",lists,"min"=>-20,"max"=>20)
fig_lonlat_anml("RH",lists,"min"=>-50,"max"=>50)
fig_lonlat_anml("H2OLiq",lists,"min"=>-0.5,"max"=>0.5)
fig_lonlat_anml("PrcWtr",lists,"min"=>-50,"max"=>50,"nlev"=>20)      
fig_lonlat_anml("U",lists,"min"=>-20,"max"=>20,"nlev"=>20)      
fig_lonlat_anml("V",lists,"min"=>-10,"max"=>10)      

DCL.grcls
rename_img_file("omega",__FILE__)
