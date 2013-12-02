#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# 
# 
include NumRu
include Math
include NMath
require File.expand_path(File.dirname(__FILE__)+"/"+"utiles_spe.rb")
include Utiles_spe
require "numru/ggraph"
require 'numru/gphys'

module MKfig

  def merid_fig(var_name,list,hash={}) # 子午面断面
    list.dir.each_index do |n|
      gp = gpopen(Utiles_spe.str_add(list.dir[n],var_name)+'.nc',var_name)
      next if gp.nil?
      # 時間平均
      gp = gp.mean("time") if gp.axnames.include?("time")
      # 経度平均
      gp = gp.mean("lon") if gp.axnames.include?("lon")
      
      # 
      if gp.max.to_f > 1e+10 then
        gp = gp*1e-10
        gp.units = "10^10 " + gp.units.to_s
      end
  
      fig_opt = {'color_bar'=>true,
                 'title'=>gp.long_name + " " + list.name[n],
                 'annotate'=>false,
                 'nlev'=>20}.merge(hash)
      GGraph.tone_and_contour(gp, true,fig_opt)
    end
  end
#------------------------------------------------  
  def lat_fig(var_name,list,hash={}) # 緯度分布
    lc = 23
    vx = 0.82
    vy = 0.8
    list.dir.each_index do |n|
      # データの取得
      gp = gpopen(list.dir[n] + var_name + ".nc",var_name)
      next if gp.nil?
  
      # 高さ方向にデータがある場合は最下層を取り出す
      gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
  
      # 時間平均経度平均
      gp = gp.mean('time') if gp.axnames.include?("time")
      gp = gp.mean(0) if gp.axnames[0] != "lat"
  
      # 
      gp = Utiles_spe.wm2mmyr(gp) if var_name.include?("Rain") 
  
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
#------------------------------------------------
  def lon_fig(var_name,list,hash={})
    lc = 23
    vx = 0.82
    vy = 0.8
    list.dir.each_index do |n|
      # データの取得
      gp = gpopen(list.dir[n] + var_name + ".nc",var_name)
      next if gp.nil?
  
      # 高さ方向にデータがある場合は最下層を取り出す
      gp = gp.cut("sig"=>1) if gp.axnames.include?("sig")
  
      # 時間変化
      gp = gp.mean('time') if gp.axnames.include?("time")

      # 緯度切り出し
      lat = 0
      lat = Lat if defined?(Lat)
      gp = gp.cut("lat"=>lat)
  
      # 降水量の単位変換
#      gp = Utiles_spe.wm2mmyr(gp) if var_name.include?("Rain") 

      gp = fix_axis_local(gp)
      
      # 描画
      xmax = 360
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[0,xmax,nil,nil])

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

# -----------------------------------------------
  def lonlat(var_name,list,hash={}) #水平断面
    list.dir.each_index do |n|
      gp = gpopen(list.dir[n] + var_name + ".nc",var_name)
      next if gp.nil?
  
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
#---------------------------------------------
  def lonsig(var_name,list,hash={}) # 赤道断面
    list.dir.each_index do |n|
      gp = gpopen(list.dir[n] + var_name + ".nc",var_name)
      next if gp.nil?
  
      # 時間平均
      gp = gp.mean("time") if !gp.axnames.index("time").nil?
  
      # 緯度切り出し
      lat = 0
      lat = Lat if defined?(Lat)
      gp = gp.cut("lat"=>lat)
         
      # 横軸最大値
      gp = fix_axis_local(gp)
      xmax = 360
      # 描画
      GGraph.set_axes("xlabelint"=>xmax/4,'xside'=>'bt', 'yside'=>'lr')
      GGraph.set_fig('window'=>[0,xmax,nil,nil])
  
      fig_opt = {'title'=>gp.long_name + " " + list.name[n],
                 'annotate'=>false,
                 'color_bar'=>true}.merge(hash)
      GGraph.tone_and_contour gp ,true, fig_opt
    end
  end
# -------------------------------------------
  def fix_axis_local(gp)
    xcoord = gp.axis(0).to_gphys.val
    xmax = (xcoord[1]-xcoord[0])*xcoord.length
    return gp if xmax == 360
    a = 360/xmax
    local = gp.axis(0).pos * a
    local.units = "degree"
    gp.axis(0).set_pos(local)
    return gp
  end
# -------------------------------------------
  def set_figopt
    figopt = {}
    figopt["max"] = Max if defined?(Max)
    figopt["min"] = Min if defined?(Min)
    figopt["nlev"] = Nlev if defined?(Nlev)
    figopt["clr_max"] = ClrMax if defined?(ClrMax)
    figopt["clr_min"] = ClrMin if defined?(ClrMin)        
    figopt = parse_Figopt(figopt)
    return figopt
  end
# -------------------------------------------
  def parse_Figopt(figopt)
    return figopt if !defined? Figopt
    if Figopt.class == Array
      result = []
      Figopt.each{|hash| result = hash.merge(figopt)}
    else
      result = Figopt.merge(figopt)
    end
    return result
  end
# -------------------------------------------
  def rename_img_file(id,scrfile) 
    id = id.id if id.class == Explist
    img_lg = id+File.basename(scrfile,".rb").sub("mkfig","")
    img_lg += "_lat#{Lat.to_i}" if defined?(Lat)
    img_lg += "_#{VarName}" if defined?(VarName)
    if IWS == 2 
      File.rename("dcl.ps","#{img_lg}.ps")
    elsif IWS == 4
      Dir.glob("dcl_*.png").each{ |filename|
        File.rename(filename,filename.sub("dcl",img_lg)) }
    end
  end  
end
