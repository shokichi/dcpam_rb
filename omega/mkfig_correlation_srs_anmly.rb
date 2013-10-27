#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 実験シリーズの偏差
# 相関係数
# A-C, A-D
#

require 'numru/ggraph'
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/utiles_omega.rb")
require 'optparse'
include Utiles_spe
include NumRu
include Math


def fig_correlation_anml(var_name,lists)
  all = Omega::Anomaly.new(var_name,lists[:all])
  diurnal = Omega::Anomaly.new(var_name,lists[:diurnal])
  coriolis = Omega::Anomaly.new(var_name,lists[:coriolis])
  plus_dc = diurnal.plus(coriolis) # C+D
  del_adc = all.minus(plus_dc)     # A-(C+D)

  coef_D = correlation_coefficient(all.anomaly,diurnal.anomaly) # .class = GPhys 
  coef_C = correlation_coefficient(all.anomaly,coriolis.anomaly)
  coef_DC = correlation_coefficient(all.anomaly,del_adc.anomaly) 

  GGraph.mark coef_D, true, "min"=>0, "max"=>1, "title"=>"correlation coefficient"
  GGraph.mark coef_C, false, "index"=>20
  GGraph.mark coef_DC, false, "index"=>30

  if defined?(CreateDatFile)
    # テキストファイルの作成
    fin = File.open("omega_correlation_clm.dat","w")
    
    fin.print "#rotation rate\t"
    fin.print "D\t"
    fin.print "C\t"
    fin.print "DC\n"
    
    coef.each_index do |n|
      fin.print coef_D.axis(0).to_gphys[n].to_f+"\t"
      fin.print coef_D[n].to_f+"\t"
      fin.print coef_C[n].to_f+"\t"
      fin.print coef_X[n].to_f+"\n"
      fin.close
  end
  end
end

opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("--dat") {CreateDatFile = true}
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

fig_correlation_anml("OSRA",lists)

DCL.grcls
rename_img_file("omega",__FILE__)
