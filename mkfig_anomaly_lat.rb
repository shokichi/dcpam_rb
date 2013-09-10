#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 偏差シリーズ
#  


# 
require "numru/ggraph"
require 'optparse'
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/make_figure.rb")
include MKfig
include Utiles_spe
include NumRu


def lat_anomaly(var_name,list,hash={})
  # 基準データ
  gp_ref = gpopen(list.dir[list.refnum]+var_name+".nc",var_name)
  if gp_ref.nil?
    print "Refarence file is not exist [#{list.dir[list.refnum]}](#{var_name})\n"
    return
  end
  gp_ref = cut_and_mean(gp_ref)

  # 降水量の単位変換
#  gp = Utiles_spe.wm2mmyr(gp) if var_name[0..3]=="Rain" 

  # 比較データ
  list.dir.each_index do |n|
    gp = gpopen(list.dir[n] + var_name + ".nc",var_name)
    next if gp.nil?

    gp = cut_and_mean(gp)

    #
    annml = gp.copy
    annml.val = gp.val-gp_ref.val

    # 描画
    if n == 0 then
      lc = 23 if list.ref != nil
      vx = 0.82
      vy = 0.8
      fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
      GGraph.line( annml ,true ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    elsif n == list.refnum
      lc_ref = 13
      vx = 0.82
      vy = 0.8 - 0.025*n
      fig_opt = {'index'=>lc_ref}      
      GGraph.line( annml ,false ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc_ref)     
    else
      lc = 23 + 10*n
      vx = 0.82
      vy = 0.8 - 0.025*n
      fig_opt = {'index'=>lc}      
      GGraph.line( annml ,false ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    end 
  end
end



def cut_and_mean(gp)
  # 時間平均
  gp = gp.mean("time") if gp.axnames.index("time") != nil

  # 高さ方向の次元をカット
  gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
  gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")

  return gp.mean(0)
end

# option
opt = OptionParser.new
opt.on("-r","--rank") {Flag_rank = true}
opt.on("-n VAR","--name=VAR") {|name| VarName = name}
opt.on("-o OPT","--figopt=OPT") {|hash| Figopt = hash}
opt.on("--ps") { IWS = 1}
opt.on("--png") { 
  DCL::swlset('lwnd',false)
  IWS = 4
}
opt.parse!(ARGV) 

list = Utiles_spe::Explist.new(ARGV[0])
varname = VarName if defined?(VarName)
IWS = 1 if !defined?(IWS) or IWS.nil?

# DCL set
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

lat_anomaly("OSRA",list,"min"=>-250,"max"=>250)
lat_anomaly("OLRA",list,"min"=>-100,"max"=>100)
lat_anomaly("EvapA",list,"min"=>-150,"max"=>150)
lat_anomaly("SensA",list,"min"=>-100,"max"=>100)
lat_anomaly("SSRA",list,"min"=>-200,"max"=>200)
lat_anomaly("SLRA",list,"min"=>-60,"max"=>60)
lat_anomaly("Rain",list,"min"=>-800,"max"=>800)
lat_anomaly("RainCumulus",list,"min"=>50,"max"=>50)
lat_anomaly("RainLsc",list,"min"=>50,"max"=>50)
lat_anomaly("SurfTemp",list,"min"=>-30,"max"=>30)
lat_anomaly("Temp",list,"min"=>-20,"max"=>20)
lat_anomaly("RH",list,"min"=>-10,"max"=>10)
lat_anomaly("H2OLiq",list,"min"=>-5e-5,"max"=>5e-5)
lat_anomaly("PrcWtr",list,"min"=>-50,"max"=>50)      
lat_anomaly("U",list,"min"=>-20,"max"=>20)      
lat_anomaly("V",list,"min"=>-10,"max"=>10)      

=begin
lonlat_anomaly("DQVapDtDyn",list)      
lonlat_anomaly("DQVapDtVDiff",list)    
lonlat_anomaly("DQVapDtCond",list,"min"=>-3e-7,"max"=>0)
lonlat_anomaly("DQVapDtCumulus",list,"min"=>-3e-7,"max"=>0)  
lonlat_anomaly("DQVapDtLsc",list,"min"=>-3e-7,"max"=>0)
lonlat_anomaly("DTempDtRadS",list)
lonlat_anomaly("DTempDtRadL",list)
lonlat_anomaly("DTempDtDyn",list)   
lonlat_anomaly("DTempDtVDiff",list)
lonlat_anomaly("DTempDtCond",list)     
lonlat_anomaly("DTempDtCumulus",list)  
lonlat_anomaly("DTempDtLsc",list)   
lonlat_anomaly("DTempDtDryConv",list)  
=end
DCL.grcls
rename_img_file(list,__FILE__)
