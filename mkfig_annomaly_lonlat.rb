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
  begin
    gp_ref = GPhys::IO.open(list.dir[list.refnum]+var_name+".nc",var_name)
  rescue
    print "Refarence file is not exist [#{list.dir[list.refnum]}](#{var_name})\n"
    return
  end
  gp_ref = cut_and_mean(gp_ref)

  # 比較データ
  list.dir.each_index do |n|
    begin
      gp = GPhys::IO.open(list.dir[n] + var_name + ".nc",var_name)
    rescue
      print "[#{var_name}.nc](#{list.dir[n]}) is not exist\n"
      next
    end
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

def cut_and_mean(gp)
  # 時間平均
  gp = gp.mean("time") if gp.axnames.index("time") != nil

  # 高さ方向の次元をカット
  gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
  gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")

  return gp
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
clrmp = 14  # カラーマップ
DCL.sgscmn(clrmp)
DCL.gropn(iws)
#DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

lonlat_annomaly("OSRA",list,"min"=>-250,"max"=>250,"nlev"=>20)
lonlat_annomaly("OLRA",list,"min"=>-100,"max"=>100,"nlev"=>20)
lonlat_annomaly("EvapA",list,"min"=>-150,"max"=>150)
lonlat_annomaly("SensA",list,"min"=>-100,"max"=>100,"nlev"=>20)
lonlat_annomaly("SSRA",list,"min"=>-200,"max"=>200,"nlev"=>20)
lonlat_annomaly("SLRA",list,"min"=>-60,"max"=>60,"nlev"=>12)
lonlat_annomaly("Rain",list,"min"=>-800,"max"=>800,"nlev"=>16)
lonlat_annomaly("RainCumulus",list,"min"=>50,"max"=>50)
lonlat_annomaly("RainLsc",list,"min"=>50,"max"=>50)
lonlat_annomaly("SurfTemp",list,"min"=>-30,"max"=>30,"nlev"=>12)
lonlat_annomaly("Temp",list,"min"=>-20,"max"=>20)
lonlat_annomaly("RH",list,"min"=>-10,"max"=>10)
lonlat_annomaly("H2OLiq",list,"min"=>-5e-5,"max"=>5e-5)
lonlat_annomaly("PrcWtr",list,"min"=>-50,"max"=>50,"nlev"=>20)      
lonlat_annomaly("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
lonlat_annomaly("V",list,"min"=>-10,"max"=>10)      

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
