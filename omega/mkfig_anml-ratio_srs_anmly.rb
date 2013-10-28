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


def fig_scat_anml(var_name,lists,hash={})
  all = Omega::Anomaly.new(var_name,lists[:all])
  all2 = Omega::Anomaly.new(var_name,lists[:all])
  diurnal = Omega::Anomaly.new(var_name,lists[:diurnal])
  diurnal2 = Omega::Anomaly.new(var_name,lists[:diurnal])
  coriolis = Omega::Anomaly.new(var_name,lists[:coriolis])
#  Omega.lonlat2(all.anomaly,lists[:all],{"add"=>"A "}.merge(hash))
  Omega.lonlat2(diurnal.over(all).anomaly,lists[:diurnal],{"add"=>"D "}.merge(hash))
  Omega.lonlat2(coriolis.over(all).anomaly,lists[:coriolis],{"add"=>"C "}.merge(hash))
  plus_dc = diurnal2.plus(coriolis)
  del_adc = all2.minus(plus_dc)
  Omega.lonlat2(plus_dc.over(all).anomaly,lists[:diurnal],{"add"=>"C+D "}.merge(hash))
  Omega.lonlat2(del_adc.over(all).anomaly,lists[:all],{"add"=>"A-D-C "}.merge(hash))

end

def scat2(gpa1,gpa2,list,hash={})
  list.name.each_index do |n|
    gpy = gpa1.anomaly[n]
    n2 = gpa2.legend.index(gpa1.legend[n])
    next if n2.nil?
    gpx = gpa2.anomaly[n2]

    if hash["add"]
      addtitle = hash["add"]
      hash.delete("add")
    else
      addtitle = ""
    end

    GGraph.set_fig('window'=>[nil,nil,nil,nil])
    fig_opt = {'title'=>addtitle + gpx.long_name + " " + list.name[n],
        'annotate'=>false}.merge(hash)
    GGraph.scatter gpx, gpy,true,fig_opt
  end
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

fig_scat_anml("OSRA",lists,"min"=>-5,"max"=>5,"nlev"=>20)

DCL.grcls
rename_img_file("omega",__FILE__)
