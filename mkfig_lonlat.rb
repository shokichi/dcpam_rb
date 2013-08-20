#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu


def lonlat(var_name,list,hash={})
  list.dir.each_index do |n|
    begin
      gp = GPhys::IO.open(list.dir[n] + var_name + ".nc",var_name)
    rescue
      print "[#{var_name}.nc](#{list.dir[n]}) is not exist\n"
      next
    end

    # 時間平均
    gp = gp.mean("time") if gp.axnames.index("time") != nil

    # 高さ方向の次元をカット
    gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
    gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")
 
    # 横軸最大値
    xcoord = gp.axis(0).to_gphys.val
    xmax = (xcoord[1]-xcoord[0])*xcoord.length

    # 描画
    GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>[0,xmax,-90,90])

    fig_opt = {'title'=>gp.long_name + " " + list.name[n],'annotate'=>false,'color_bar'=>true}
    GGraph.tone_and_contour gp ,true, fig_opt.merge(hash)
  end
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

lonlat("OSRA",list,"min"=>-1200,"max"=>0)
lonlat("OLRA",list,"min"=>0,"max"=>500,"nlev"=>20)
lonlat("EvapA",list,"max"=>1000)
lonlat("SensA",list,"max"=>200,"nlev"=>20)
lonlat("SSRA",list,"min"=>-1000)
lonlat("SLRA",list,"min"=>0,"max"=>200,"nlev"=>20)
lonlat("Rain",list,"min"=>0,"max"=>1000,"nlev"=>20)
lonlat("RainCumulus",list,"min"=>0,"max"=>500)
lonlat("RainLsc",list,"min"=>0,"max"=>500)
lonlat("SurfTemp",list,"min"=>220,"max"=>360)
lonlat("Temp",list,"min"=>220,"max"=>320)
lonlat("RH",list,"min"=>0,"max"=>100)
lonlat("H2OLiq",list,"min"=>0,"max"=>4e-5)
lonlat("PrcWtr",list,"min"=>0,"max"=>100,"nlev"=>20)      
lonlat("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
lonlat("V",list,"min"=>-10,"max"=>10)      

=begin
lonlat("DQVapDtDyn",list)      
lonlat("DQVapDtVDiff",list)    
lonlat("DQVapDtCond",list,"min"=>-3e-7,"max"=>0)
lonlat("DQVapDtCumulus",list,"min"=>-3e-7,"max"=>0)  
lonlat("DQVapDtLsc",list,"min"=>-3e-7,"max"=>0)
lonlat("DTempDtRadS",list)
lonlat("DTempDtRadL",list)
lonlat("DTempDtDyn",list)   
lonlat("DTempDtVDiff",list)
lonlat("DTempDtCond",list)     
lonlat("DTempDtCumulus",list)  
lonlat("DTempDtLsc",list)   
lonlat("DTempDtDryConv",list)  
=end
DCL.grcls

if ARGV.index("-ps") 
  system("mv dcl.ps #{list.id}_lonlat.ps")
elsif ARGV.index("-png")
  system("rename 's/dcl_/#{list.id}_lonlat_/' dcl_*.png")
end
