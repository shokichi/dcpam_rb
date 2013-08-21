#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# standerd figure
# No.4 


# 
require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu


def lonsig(var_name,list,hash={})
  list.dir.each_index do |n|
    begin
      gp = GPhys::IO.open(list.dir[n] + var_name + ".nc",var_name)
    rescue
      print "[#{var_name}.nc](#{list.dir[n]}) is not exist\n"
      next
    end

    # 時間平均
    gp = gp.mean("time") if !gp.axnames.index("time").nil?

    # 緯度方向の次元をカット
    if !hash.include?("lat") then
      lat = 0 
    else
      lat = hash["lat"]
      hash.delete("lat")
    end
    gp = gp.cut("lat"=>lat)
 
    # 
    # 横軸最大値
    xcoord = gp.axis(0).to_gphys.val
    xmax = (xcoord[1]-xcoord[0])*xcoord.length

    # 描画
    GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>[0,xmax,nil,nil])

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

lonsig("Temp",list,"min"=>120,"max"=>320,"nlev"=>20)
lonsig("DQVapDtCond",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)
lonsig("DQVapDtCumulus",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>20)  
lonsig("DQVapDtLsc",list,"min"=>-2e-7,"max"=>2e-7,"nlev"=>40)
lonsig("RH",list,"min"=>0,"max"=>100)
lonsig("H2OLiq",list,"min"=>0,"max"=>1e-4)
lonsig("U",list,"min"=>-20,"max"=>20,"nlev"=>20)      
lonsig("V",list,"min"=>-10,"max"=>10)      

=begin
lonlat("DQVapDtDyn",list)
lonlat("DQVapDtVDiff",list)
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
  system("mv dcl.ps #{list.id}_lonsig.ps")
elsif ARGV.index("-png")
  system("rename 's/dcl_/#{list.id}_lonsig_/' dcl_*.png")
end
