#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 偏差 -- 子後面断面 --
# 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu


def merid_annomaly(var_name,list,hash={})
  # 基準データ
  gp_ref = gpopen(list.dir[list.refnum]+var_name+".nc",var_name)
  if gp_ref.nil? then
    print "Refarence file is not exist\n"
    return
  end
  gp_ref = cut_and_mean(gp_ref)

  # 比較データ
  list.dir.each_index do |n|
    gp = gpopen(list.dir[n] + var_name + ".nc",var_name)
    next if gp.nil?

    gp = cut_and_mean(gp)

    # 偏差の計算
    annml = gp.copy
    annml.val = gp.val-gp_ref.val

    # 描画
    fig_opt = {'title'=>gp.long_name + " " + list.name[n],
               'annotate'=>false,'color_bar'=>true}
    GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>[-90,90,nil,nil])
    GGraph.tone_and_contour( annml ,true, fig_opt.merge(hash))
  end
end

def merid_annomaly(var_name,list,hash={})
  # 基準データ
  gp_ref = gpopen(list.dir[list.refnum]+var_name+".nc",var_name)
  if gp_ref.nil? then
    print "Refarence file is not exist\n"
    return
  end
  gp_ref = cut_and_mean(gp_ref)

  # 比較データ
  list.dir.each_index do |n|
    gp = gpopen(list.dir[n] + var_name + ".nc",var_name)
    next if gp.nil?

    gp = cut_and_mean(gp)

    # 偏差の計算
    annml = gp.copy
    annml.val = gp.val-gp_ref.val*glmean(gp).val/glmean(gp_ref).val

    # 描画
    fig_opt = {'title'=>gp.long_name + " " + list.name[n],
               'annotate'=>false,'color_bar'=>true}
    GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>[-90,90,nil,nil])
    GGraph.tone_and_contour( annml ,true, fig_opt.merge(hash))
  end
end

def cut_and_mean(gp)
  # 時間平均
  gp = gp.mean("time") if !gp.axnames.index("time").nil
  # 経度平均
  gp = gp.mean("lon") if !gp.axnames.index("lon").nil

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

merid_annomaly("Temp",list,"min"=>220,"max"=>320)
merid_annomaly("RH",list,"min"=>0,"max"=>100)
merid_annomaly("H2OLiq",list,"min"=>0,"max"=>4e-5)

merid_annomaly("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
merid_annomaly("V",list,"min"=>-10,"max"=>10)      

=begin
merid_annomaly("DQVapDtDyn",list)      
merid_annomaly("DQVapDtVDiff",list)    
merid_annomaly("DQVapDtCond",list,"min"=>-3e-7,"max"=>0)
merid_annomaly("DQVapDtCumulus",list,"min"=>-3e-7,"max"=>0)  
merid_annomaly("DQVapDtLsc",list,"min"=>-3e-7,"max"=>0)
merid_annomaly("DTempDtRadS",list)
merid_annomaly("DTempDtRadL",list)
merid_annomaly("DTempDtDyn",list)   
merid_annomaly("DTempDtVDiff",list)
merid_annomaly("DTempDtCond",list)     
merid_annomaly("DTempDtCumulus",list)  
merid_annomaly("DTempDtLsc",list)   
merid_annomaly("DTempDtDryConv",list)  
=end
DCL.grcls

rename_img_file(list,__FILE__)
