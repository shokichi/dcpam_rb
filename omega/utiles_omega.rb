#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 自転角速度変更実験用スクリプト
#

require "numru/ggraph"
require 'numru/gphys'
require File.expand_path(File.dirname(__FILE__)+"/../lib/make_figure.rb")
require 'optparse'
include Utiles_spe
include MKfig
include NumRu
include Math
include NMath

module Omega
  # 定数
  SolarConst = UNumeric[1366.0, "W.m-2"]
  StB = UNumeric[5.67e-8, "W.m-2.K-4"]
# -------------------------------------------
def self.lat_fig2(data,list,hash={}) # 緯度分布
  lc = 23
  vx = 0.82
  vy = 0.8
  list.dir.each_index do |n|
    # データの取得
    gp = data[n]

    # 高さ方向にデータがある場合は最下層を取り出す
    gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
  
    # 時間平均経度平均
    gp = gp.mean('time') if gp.axnames.include?("time")
    gp = gp.mean(0) if gp.axnames[0] != "lat"
  
    # 降水量の単位変換
    gp = Utiles_spe.wm2mmyr(gp) if gp.name.include?("Rain") 
  
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
      DCL.sgtxzv(vx+0.05,vy,list.name[n],0.015,0,-1,3)
      DCL::sgplzv([vx,vx+0.04],[vy,vy],1,lc)
    end 
  end
end
#---------------------------------------------
def self.lonlat2(data,list,hash={}) #水平断面
  list.dir.each_index do |n|
    gp = data[n]
    next if gp.nil?

    if gp.name == "H2OLiq" then
      ps = GPhys::IO.open gp.data.file.path.sub("H2OLiq","Ps"),"Ps"
      sig_weight = GPhys::IO.open("/home/ishioka/link/all/omega1/data/H2OLiq.nc","sig_weight")
      gp = (gp * ps * sig_weight).sum("sig")/Grav 
    end
    # 時間平均
    gp = gp.mean("time") if gp.axnames.include?("time")
  
    # 高さ方向の次元をカット
    gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
    gp = gp.cut("sigm"=>1) if gp.axnames.include?("sigm")
   
    # 横軸最大値
    xcoord = gp.axis(0).to_gphys.val
    xmax = (xcoord[1]-xcoord[0])*xcoord.length
  
    # 描画
    GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
    GGraph.set_fig('window'=>[0,xmax,-90,90])

    fig_opt = {'title'=>gp.long_name + " " + list.name[n],
               'annotate'=>false,
               'color_bar'=>true}.merge(hash)
    GGraph.tone_and_contour gp ,true, fig_opt
  end
end
#------------------------------------------- 
end
   
