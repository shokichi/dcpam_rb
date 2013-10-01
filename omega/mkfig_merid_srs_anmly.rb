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



def fig_merid_anml(var_name,lists,hash={})
  p lists["all"].name  
  all = Anomaly.new(var_name,lists["all"])
  diurnal = Anomaly.new(var_name,lists["diurnal"])
  coriois = Anomaly.new(var_name,lists["coriolis"])
  Omega.merid2(delt(all,diurnal),lists["all"],hash)
  Omega.merid2(delt(all,coriolis),lists["all"],hash)
end

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--ps") { IWS = 2}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
a_list = "/home/ishioka/link/all/fig/list/omega_all_MTlocal.list"
d_list = "/home/ishioka/link/diurnal/fig/list/omega_diurnal_MTlocal.list"
c_list = "/home/ishioka/link/coriolis/fig/list/omega_coriolis_MTlocal.list"

# DCL set
IWS = 1 if !defined?(IWS)
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

lists={
  "all"=>Utiles_spe::Explist.new(a_list),
  "diurnal"=>Utiles_spe::Explist.new(d_list),
  "coriolis"=>Utiles_spe::Explist.new(c_list)
}

fig_merid_anml("Temp",list,"min"=>-20,"max"=>20)
fig_merid_anml("RH",list,"min"=>-50,"max"=>50)
fig_merid_anml("H2OLiq",list,"min"=>-1e-4,"max"=>1e-4)

fig_merid_anml("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
fig_merid_anml("V",list,"min"=>-10,"max"=>10)      

DCL.grcls

rename_img_file(list,__FILE__)
