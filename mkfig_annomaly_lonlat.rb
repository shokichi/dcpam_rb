#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu


def lonlat_annomaly(var_name,list,hash={})
  # 基準データ
  gp_ref =gp.open(list.dir[list.refnum]+var_name+".nc",var_name)
  if gp_ref.nil?
    print "Refarence file is not exist [#{list.dir[list.refnum]}](#{var_name})\n"
    return
  end

  gp_ref = cut_and_mean(gp_ref)

  # 比較データ
  list.dir.each_index do |n|
    gp = GPhys::IO.open(list.dir[n] + var_name + ".nc",var_name)
    next if gp.nil?
    gp = cut_and_mean(gp)

    # 横軸最大値
    xcoord = gp.axis(0).to_gphys.val
    xmax = (xcoord[1]-xcoord[0])*xcoord.length

    #
    annml = gp.copy
    annml.val = gp.val-gp_ref.val

    # 描画
    fig_opt = {'title'=>gp.long_name + " " + list.name[n],
               'annotate'=>false,'color_bar'=>true}
    GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>[0,xmax,-90,90])
    GGraph.tone_and_contour( annml ,true, fig_opt.merge(hash))
  end
end

def lonlat_annomaly_fix(var_name,list,hash={})
  # 基準データ
  gp_ref = gpopen(list.dir[list.refnum]+var_name+".nc",var_name)
  if gp_ref.nil? then
    print "Refarence file is not exist [#{list.dir[list.refnum]}](#{var_name})\n"
    return
  end
  gp_ref = cut_and_mean(gp_ref)

  # 比較データ
  list.dir.each_index do |n|
    gp = gpopen(list.dir[n] + var_name + ".nc",var_name)
    next if gp.nil?

    gp = cut_and_mean(gp)

    # 横軸最大値
    xcoord = gp.axis(0).to_gphys.val
    xmax = (xcoord[1]-xcoord[0])*xcoord.length

    # 偏差の計算
    annml = gp.copy
    annml.val = gp.val-gp_ref.val* glmean(gp).val/glmean(gp_ref).val

    # 描画
    fig_opt = {'title'=>gp.long_name + " " + list.name[n],
               'annotate'=>false,'color_bar'=>true}
    GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>[0,xmax,-90,90])
    GGraph.tone_and_contour( annml ,true, fig_opt.merge(hash))
  end
end


def cut_and_mean(gp)
  # 時間平均
  gp = gp.mean("time") if gp.axnames.index("time") != nil

  # 高さ方向の次元をカット
  if gp.name == "H2OLiq"
    ps = gpopen gp.data.file.path.sub("H2OLiq","Ps"),"Ps"
    sig_weight = gpopen("/home/ishioka/link/all/omega1/data/H2OLiq.nc","sig_weight")
    gp = (gp * ps * sig_weight).sum("sig")/Grav 
  end
  gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
  gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")

  return gp
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
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(IWS)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

#=begin
lonlat_annomaly("OSRA",list,"min"=>-250,"max"=>250,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
lonlat_annomaly("OLRA",list,"min"=>-100,"max"=>100,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
lonlat_annomaly("EvapA",list,"min"=>-150,"max"=>150,"clr_min"=>99,"clr_max"=>13)
lonlat_annomaly("SensA",list,"min"=>-100,"max"=>100,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
lonlat_annomaly("SSRA",list,"min"=>-200,"max"=>200,"nlev"=>20,"clr_min"=>99,"clr_max"=>13)
lonlat_annomaly("SLRA",list,"min"=>-60,"max"=>60,"nlev"=>12,"clr_min"=>99,"clr_max"=>13)
lonlat_annomaly("Rain",list,"min"=>-800,"max"=>800,"nlev"=>16)
lonlat_annomaly("RainCumulus",list,"min"=>-500,"max"=>500,"nlev"=>20)
lonlat_annomaly("RainLsc",list,"min"=>-500,"max"=>500,"nlev"=>20)
lonlat_annomaly("SurfTemp",list,"min"=>-30,"max"=>30,"nlev"=>12)
lonlat_annomaly("Temp",list,"min"=>-20,"max"=>20)
lonlat_annomaly("RH",list,"min"=>-50,"max"=>50)
lonlat_annomaly("H2OLiq",list,"min"=>-0.5,"max"=>0.5)
lonlat_annomaly("PrcWtr",list,"min"=>-50,"max"=>50,"nlev"=>20)      
lonlat_annomaly("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
lonlat_annomaly("V",list,"min"=>-10,"max"=>10)      
#=end
=begin
lonlat_annomaly_fix("OSRA",list,"min"=>-250,"max"=>250,"nlev"=>20)
lonlat_annomaly_fix("OLRA",list,"min"=>-100,"max"=>100,"nlev"=>20)
lonlat_annomaly_fix("EvapA",list,"min"=>-150,"max"=>150)
lonlat_annomaly_fix("SensA",list,"min"=>-100,"max"=>100,"nlev"=>20)
lonlat_annomaly_fix("SSRA",list,"min"=>-200,"max"=>200,"nlev"=>20)
lonlat_annomaly_fix("SLRA",list,"min"=>-60,"max"=>60,"nlev"=>12)
lonlat_annomaly_fix("Rain",list,"min"=>-800,"max"=>800,"nlev"=>16)
#lonlat_annomaly_fix("RainCumulus",list,"min"=>50,"max"=>50)
#lonlat_annomaly_fix("RainLsc",list,"min"=>50,"max"=>50)
lonlat_annomaly_fix("SurfTemp",list,"min"=>-30,"max"=>30,"nlev"=>12)
lonlat_annomaly_fix("Temp",list,"min"=>-20,"max"=>20)
lonlat_annomaly_fix("RH",list,"min"=>-50,"max"=>50)
lonlat_annomaly_fix("H2OLiq",list,"min"=>-5e-5,"max"=>5e-5)
lonlat_annomaly_fix("PrcWtr",list,"min"=>-50,"max"=>50,"nlev"=>20)      
lonlat_annomaly_fix("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
lonlat_annomaly_fix("V",list,"min"=>-10,"max"=>10)      
=end
=begin
lonlat_annomaly("DQVapDtDyn",list)      
lonlat_annomaly("DQVapDtVDiff",list)    
lonlat_annomaly("DQVapDtCond",list,"min"=>-3e-7,"max"=>0)
lonlat_annomaly("DQVapDtCumulus",list,"min"=>-3e-7,"max"=>0)  
lonlat_annomaly("DQVapDtLsc",list,"min"=>-3e-7,"max"=>0)
lonlat_annomaly("DTempDtRadS",list)
lonlat_annomaly("DTempDtRadL",list)
lonlat_annomaly("DTempDtDyn",list)   
lonlat_annomaly("DTempDtVDiff",list)
lonlat_annomaly("DTempDtCond",list)     
lonlat_annomaly("DTempDtCumulus",list)  
lonlat_annomaly("DTempDtLsc",list)   
lonlat_annomaly("DTempDtDryConv",list)  
=end
DCL.grcls

rename_img_file(list,__FILE__)
