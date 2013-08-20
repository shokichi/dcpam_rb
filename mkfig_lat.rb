#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 緯度分布の図を作成
# 

require "numru/ggraph"
require File.expand_path(File.dirname(__FILE__)+"/"+"lib/utiles_spe.rb")
include Utiles_spe
include NumRu


def lat_fig(var_name,list,hash={})
  lc = 23
  vx = 0.82
  vy = 0.8
  list.dir.each_index do |n|
    # データの取得
    begin
      gp = gpopen(dir[n] + var_name + ".nc",var_name)
    rescue
      print "[#{var_name}.nc](#{dir[n]}) is not exist\n"
      next
    end

    # 高さ方向にデータがある場合は最下層を取り出す
    gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")

    # 時間平均経度平均
    gp = gp.mean('time') if gp.axnames.include?("time")
    gp = gp.mean('lon') if gp.axnames.include?("time")

    # 降水量の単位変換
    gp = Utiles_spe.wm2mmyr(gp) if var_name[0..3]=="Rain" 

    # 描画
    vy = vy - 0.025
    if n == 0 then
      lc = 13 if list.ref.nil?
      fig_opt = {'index'=>lc,'legend'=>false,'annotate'=>false}
      GGraph.line( gp ,true ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    elsif n == list.refnum
      lc_ref = 13
      fig_opt = {'index'=>lc_ref}      
      GGraph.line( gp ,false ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc_ref)     
    else
      lc = lc + 10
      fig_opt = {'index'=>lc}      
      GGraph.line( gp ,false ,fig_opt.merge(hash))
      DCL.sgtxzv(vx+0.05,vy,name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    end 
  end
end


# 
list = Utiles_spe::Explist.new(ARGV[0])

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


lat_fig("OSRA",list,"min"=>0,"max"=>-320)
lat_fig("OLRA",list,"min"=>0,"max"=>320)
lat_fig("EvapA",list,"min"=>-20,"max"=>300)
lat_fig("SensA",list,"min"=>-20,"max"=>300)
lat_fig("SSRA",list,"min"=>20,"max"=>-300)
lat_fig("SLRA",list,"min"=>-20,"max"=>300)
lat_fig("Temp",list,"min"=>200,"max"=>300)
lat_fig("SurfTemp",list,"min"=>200,"max"=>300)
lat_fig("Rain",list,"min"=>0,"max"=>6000)
lat_fig("RainCumulus",list,"min"=>0,"max"=>6000)
lat_fig("RainLsc",list,"min"=>0,"max"=>6000)
lat_fig("Ps",list,"min"=>90000,"max"=>110000)
lat_fig("PrcWtr",list,"min"=>0,"max"=>50)


DCL.grcls

if ARGV.index("-ps") 
  system("mv dcl.ps #{list.id}_lat.ps")
elsif ARGV.index("-png") 
  system("rename 's/dcl_/#{list.id}_lat_/' dcl_*.png")
end
