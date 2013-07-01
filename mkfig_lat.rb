#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 緯度分布の図を作成
# 

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu


def lat_fig(var_name,dir,name,hash)
  for n in 0..dir.length-1
    # データの取得
    begin
      gp = GPhys::IO.open(dir[n] + var_name + ".nc",var_name)
    rescue
      print "[#{var_name}.nc](#{dir[n]}) is not exist\n"
      next
    end

    # 高さ方向にデータがある場合は最下層を取り出す
    if gp.axnames.index("sig") != nil then
      gp = gp.cut("sig"=>1)
    end

    # 時間平均経度平均
    if gp.rank == 3 
      gp = gp.mean('lon','time')
    elsif gp.rank == 2
      gp = gp.mean('lon')
    end

    # 降水量の単位変換
    if var_name[0..3]=="Rain" then
      gp = Utiles_spe.wm2mmyr(gp)
    end

    # 描画
    if n == 0 then
      lc = 13
      vx = 0.82
      vy = 0.8
      fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
      GGraph.line( gp ,true ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    else
      lc = lc + 10
      vy = vy - 0.025
      fig_opt = {'index'=>lc}      
      GGraph.line( gp ,false ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    end 
  end
end


# 
list=ARGV[0]
dir, name = Utiles_spe.explist(list)
if list != nil
  id_exp = list.split("/")[-1].sub(".list","")
end

# DCL open
if ARGV.index("-ps")
  DCL.gropn(2)
elsif ARGV.index("-png")
  DCL::swlset('lwnd',false)
  DCL.gropn(4)
else
  DCL.gropn(1)
end

# DCL set
# DCL.sldiv('Y',2,1)
DCL.sgpset('lcntl',true)
DCL.sgpset('isub', 96)
DCL.uzfact(1.0)

GGraph.set_axes("xlabelint"=>30,'xside'=>'bt', 'yside'=>'lr')
GGraph.set_fig('window'=>[-90,90,nil,nil])


lat_fig("OSRA",dir,name,"min"=>0,"max"=>-320)
lat_fig("OLRA",dir,name,"min"=>0,"max"=>320)
lat_fig("EvapA",dir,name,"min"=>-20,"max"=>300)
lat_fig("SensA",dir,name,"min"=>-20,"max"=>300)
lat_fig("SSRA",dir,name,"min"=>20,"max"=>-300)
lat_fig("SLRA",dir,name,"min"=>-20,"max"=>300)
lat_fig("Temp",dir,name,"min"=>200,"max"=>300)
lat_fig("SurfTemp",dir,name,"min"=>200,"max"=>300)
lat_fig("Rain",dir,name,"min"=>0,"max"=>6000)
lat_fig("RainCumulus",dir,name,"min"=>0,"max"=>6000)
lat_fig("RainLsc",dir,name,"min"=>0,"max"=>6000)
lat_fig("Ps",dir,name,"min"=>90000,"max"=>110000)
lat_fig("QVapCulumu",dir,name,"min"=>0,"max"=>50)


DCL.grcls

if ARGV.index("-ps") 
  system("mv dcl.ps #{id_exp}_lat.ps")
elsif ARGV.index("-png") 
  system("rename 's/dcl_/#{id_exp}_lat_/' dcl_*.png")
end
