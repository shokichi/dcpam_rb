#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 実験シリーズの偏差
# 相関係数
# A-C, A-D
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/../lib/dcpam.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math


def fig_correlation_anml(var_name,lists)
  all = gpaopen(var_name,lists[:all])
  diurnal = gpaopen(var_name,lists[:diurnal])
  coriolis = gpaopen(var_name,lists[:coriolis])
#  plus_dc = diurnal.plus(coriolis) # C+D
#  del_adc = all.minus(plus_dc)     # A-(C+D)

  coef_D = all.anomaly.correlation(diurnal.anomaly) # .class = GPhys 
  coef_C = all.anomaly.correlation(coriolis.anomaly)
#  coef_DC = all.correlation(plus_dc)
#  coef_ADC = all.correlation(del_adc) 

  if defined?(CreateDatFile)
    # テキストファイルの作成
    fin = File.open("omega_correlation_clm.dat","w")
    
    fin.print "#rotation rate\t"
    fin.print "D\t"
    fin.print "C\t"
    fin.print "DC\t"
    fin.print "A-DC\n"
    
    coef_D.val.to_a.each_index do |n|
      fin.print "#{coef_D.axis(0).to_gphys[n].val}\t"
      fin.print "#{coef_D[n].val}\t"
      fin.print "#{coef_C[n].val}\t"
#      fin.print "#{coef_DC[n].val}\t"
#      fin.print "#{coef_ADC[n].val}\n"
    end
    fin.close
  else
    set_dcl
    GGraph.line coef_D, true, "title"=>""
    GGraph.line coef_C, false, "index"=>20
#    GGraph.line coef_DC, false, "index"=>30
    DCL.grcls
    rename_img_file("omega",__FILE__)
  end
end

Opt = OptCharge::OptCharge.new
Opt.set

IWS = get_iws

a_list = "/home/ishioka/link/fig/list/omega_all_MTlocal.list"
d_list = "/home/ishioka/link/fig/list/omega_diurnal_MTlocal.list"
c_list = "/home/ishioka/link/fig/list/omega_coriolis_MTlocal.list"
lists={
  all:      Explist.new(a_list),
  diurnal:  Explist.new(d_list),
  coriolis: Explist.new(c_list)
}

fig_correlation_anml("OSRA",lists)

