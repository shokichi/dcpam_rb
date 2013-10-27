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
  diurnal = Omega::Anomaly.new(var_name,lists[:diurnal])
  coriolis = Omega::Anomaly.new(var_name,lists[:coriolis])
  plus_dc = diurnal.plus(coriolis)
  del_adc = all.minus(plus_dc)
  scat2(all,diurnal,lists[:diurnal],{"add"=>"A vs D "}.merge(hash))
  scat2(all,coriolis,lists[:coriolis],{"add"=>"A vs C "}.merge(hash))
  scat2(all,del_adc,lists[:all],{"add"=>"A vs A-D-C "}.merge(hash))
  scat2(all,plus_dc,lists[:diurnal],{"add"=>"A vs C+D "}.merge(hash))
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
        'annotate'=>false,
        'color_bar'=>true}.merge(hash)
    GGraph.scatter gpx, gpy,true,figopt
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

fig_scat_anml("OSRA",lists)

DCL.grcls
rename_img_file("omega",__FILE__)
