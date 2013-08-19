#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 偏差シリーズ
#  


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu


def lat_annomaly(var_name,list,hash={})
  # 基準データ
  begin
    gp_ref = GPhys::IO.open(list.dir[list.refnum]+var_name+".nc",var_name)
  rescue
    print "Refarence file is not exist [#{list.dir[list.refnum]}](#{var_name})\n"
    return
  end
  gp_ref = cut_and_mean(gp_ref)

  # 降水量の単位変換
#  gp = Utiles_spe.wm2mmyr(gp) if var_name[0..3]=="Rain" 

  # 比較データ
  list.dir.each_index do |n|
    begin
      gp = GPhys::IO.open(list.dir[n] + var_name + ".nc",var_name)
    rescue
      print "[#{var_name}.nc](#{list.dir[n]}) is not exist\n"
      next
    end
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

#
list = Utiles_spe::Explist.new(ARGV[0])

# DCL open
if ARGV.index("-ps")
  iws = 2
elsif ARGV.index("-png")
  DCL::swlset('lwnd',false)
  iws = 4
else
  iws = 1
end

# DCL set
DCL.gropn(iws)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

lat_annomaly("OSRA",list,"min"=>-250,"max"=>250)
lat_annomaly("OLRA",list,"min"=>-100,"max"=>100)
lat_annomaly("EvapA",list,"min"=>-150,"max"=>150)
lat_annomaly("SensA",list,"min"=>-100,"max"=>100)
lat_annomaly("SSRA",list,"min"=>-200,"max"=>200)
lat_annomaly("SLRA",list,"min"=>-60,"max"=>60)
lat_annomaly("Rain",list,"min"=>-800,"max"=>800)
lat_annomaly("RainCumulus",list,"min"=>50,"max"=>50)
lat_annomaly("RainLsc",list,"min"=>50,"max"=>50)
lat_annomaly("SurfTemp",list,"min"=>-30,"max"=>30)
lat_annomaly("Temp",list,"min"=>-20,"max"=>20)
lat_annomaly("RH",list,"min"=>-10,"max"=>10)
lat_annomaly("H2OLiq",list,"min"=>-5e-5,"max"=>5e-5)
lat_annomaly("PrcWtr",list,"min"=>-50,"max"=>50)      
lat_annomaly("U",list,"min"=>-20,"max"=>20)      
lat_annomaly("V",list,"min"=>-10,"max"=>10)      

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

if ARGV.index("-ps") 
  system("mv dcl.ps #{list.id}_lonlat-annml.ps")
elsif ARGV.index("-png")
  system("rename 's/dcl_/#{list.id}_lonlat-annml_/' dcl_*.png")
end
