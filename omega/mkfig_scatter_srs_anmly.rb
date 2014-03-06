#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 実験シリーズの偏差
# Scatter Plot
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
  all = gpaopen(var_name,lists[:all]).anomaly.delete(lists[:all].ref)
  diurnal = gpaopen(var_name,lists[:diurnal]).anomaly.delete(lists[:diurnal].ref)
  coriolis = gpaopen(var_name,lists[:coriolis]).anomaly.delete(lists[:coriolis].ref)
  scat2(all,coriolis,hash)
  scat2(all,diurnal,hash)
#  scat2(all,plus_dc,lists[:diurnal],{"add"=>"A vs C+D "}.merge(hash))
#  scat2(all,del_adc,lists[:all],{"add"=>"A vs A-D-C "}.merge(hash))
end


def scat(all,diurnal,coriolis,list,hash={})

  GGraph.set_fig('window'=>[-200,300,-200,300])

  list.name.each_index do |n|
    gpx = all.anomaly[n]
    n2 = diurnal.legend.index(all.legend[n])
    n3 = coriolis.legend.index(all.legend[n])
    next if n2.nil? or n3.nil?
    gpy1 = diurnal.anomaly[n2]
    gpy2 = coriolis.anomaly[n3]

    if hash["add"]
      addtitle = hash["add"]
      hash.delete("add")
    else
      addtitle = ""
    end
    fig_opt = {'title'=>addtitle + gpx.long_name + " " + list.name[n],
        'annotate'=>false}.merge(hash)
    GGraph.scatter -gpx, -gpy1,true,{"index"=>20}.merge(fig_opt)
    GGraph.scatter -gpx, -gpy2,false,{"index"=>40}.merge(fig_opt)
  end
end


def scat2(gpa1,gpa2,hash={})
#    min = gpa1.min
    #   min = gpa1.anomaly[0].min
#    GGraph.set_fig('window'=>[min,-min,min,-min])
    GGraph.set_fig('window'=>[-200,300,-200,300])

  n = 0
  gpa2.list.name.each do |legend|
    gpx = gpa1[legend]
    gpy = gpa2[legend]
    next if gpy.nil?
    fig_opt = {'title'=>gpx.long_name + " " + legend,
        'annotate'=>false}.merge(hash)
    GGraph.scatter -gpx, -gpy,true,fig_opt
    print_identifier(n)
    n += 1
  end
end

Opt = OptCharge::OptCharge.new
Opt.set
# DCL set
IWS = get_iws
set_dcl

a_list = "/home/ishioka/link/all/fig/list/omega_all_MTlocal.list"
d_list = "/home/ishioka/link/diurnal/fig/list/omega_diurnal_MTlocal.list"
c_list = "/home/ishioka/link/coriolis/fig/list/omega_coriolis_MTlocal.list"

lists={
  all:      Utiles_spe::Explist.new(a_list),
  diurnal:  Utiles_spe::Explist.new(d_list),
  coriolis: Utiles_spe::Explist.new(c_list)
}

fig_scat_anml("OSRA",lists,set_figopt)

DCL.grcls
rename_img_file("omega",__FILE__)
